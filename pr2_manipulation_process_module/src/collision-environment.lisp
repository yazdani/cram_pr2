;;;
;;; Copyright (c) 2011, Lorenz Moesenlechner <moesenle@in.tum.de>
;;; All rights reserved.
;;; 
;;; Redistribution and use in source and binary forms, with or without
;;; modification, are permitted provided that the following conditions are met:
;;; 
;;;     * Redistributions of source code must retain the above copyright
;;;       notice, this list of conditions and the following disclaimer.
;;;     * Redistributions in binary form must reproduce the above copyright
;;;       notice, this list of conditions and the following disclaimer in the
;;;       documentation and/or other materials provided with the distribution.
;;;     * Neither the name of the Intelligent Autonomous Systems Group/
;;;       Technische Universitaet Muenchen nor the names of its contributors 
;;;       may be used to endorse or promote products derived from this software 
;;;       without specific prior written permission.
;;; 
;;; THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
;;; AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
;;; IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
;;; ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE
;;; LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
;;; CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
;;; SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
;;; INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
;;; CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
;;; ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
;;; POSSIBILITY OF SUCH DAMAGE.
;;;

(in-package :pr2-manip-pm)

(defvar *collision-object-pub* nil)
(defvar *attached-object-pub* nil)

(defvar *known-collision-objects* (tg:make-weak-hash-table :weakness :key))

(defun init-collision-environment ()
  (setf *collision-object-pub*
        (roslisp:advertise "/collision_object" "mapping_msgs/CollisionObject" :latch t))
  (setf *attached-object-pub*
        (roslisp:advertise "/attached_collision_object" "mapping_msgs/AttachedCollisionObject" :latch t)))

(register-ros-init-function init-collision-environment)

(defun register-collision-object (desig)
  (declare (type object-designator desig))
  (roslisp:with-fields (added_object)
      (roslisp:call-service
       "/cop_collision" 'vision_srvs-srv:cop_add_collision
       :object_id (perception-pm:object-id (reference desig)))
    (setf (gethash desig *known-collision-objects*)
          added_object)))

(defun remove-collision-object (desig)
  (let ((collision-object (gethash desig *known-collision-objects*)))
    (when collision-object
      (roslisp:with-fields (id) collision-object
        (roslisp:publish *collision-object-pub*
                         (roslisp:make-msg
                          "mapping_msgs/CollisionObject"
                          (frame_id header) "/base_footprint"
                          (stamp header) (roslisp:ros-time)
                          id id
                          (operation operation) 1))))))

(defun attach-collision-object (side desig)
  (let ((collision-object (gethash desig *known-collision-objects*)))
    (when collision-object
      (let ((attach-object (roslisp:modify-message-copy
                            collision-object
                            (operation operation) (roslisp:symbol-code
                                                   'mapping_msgs-msg:CollisionObjectOperation
                                                   :attach_and_remove_as_object))))
        (roslisp:publish *attached-object-pub*
                         (roslisp:make-msg
                          "mapping_msgs/AttachedCollisionObject"
                          link_name (ecase side
                                      (:right "r_gripper_r_finger_tip_link")
                                      (:left "r_gripper_r_finger_tip_link"))
                          touch_links (ecase side
                                        (:right (vector
                                                 "r_gripper_palm_link"
                                                 "r_gripper_r_finger_link"
                                                 "r_gripper_l_finger_link"))
                                        (:left (vector
                                                "l_gripper_palm_link"
                                                "l_gripper_r_finger_link"
                                                "l_gripper_l_finger_link")))
                          object attach-object))))))

(defun detach-collision-object (side desig)
  (let ((collision-object (gethash desig *known-collision-objects*)))
    (when collision-object
      (let ((detach-object (roslisp:modify-message-copy
                            collision-object
                            (operation operation) (roslisp:symbol-code
                                                   'mapping_msgs-msg:CollisionObjectOperation
                                                   :detach_and_add_as_object))))
        (roslisp:publish *attached-object-pub*
                         (roslisp:make-msg
                          "mapping_msgs/AttachedCollisionObject"
                          link_name (ecase side
                                      (:right "r_gripper_r_finger_tip_link")
                                      (:left "r_gripper_r_finger_tip_link"))
                          touch_links (ecase side
                                        (:right (vector
                                                 "r_gripper_palm_link"
                                                 "r_gripper_r_finger_link"
                                                 "r_gripper_l_finger_link"))
                                        (:left (vector
                                                "l_gripper_palm_link"
                                                "l_gripper_r_finger_link"
                                                "l_gripper_l_finger_link")))
                          object detach-object))))))

(defun point->msg (point &optional (msg-type "geometry_msgs/Point"))
  (declare (type cl-transforms:3d-vector point))
  (roslisp:make-msg
   msg-type
   x (cl-transforms:x point)
   y (cl-transforms:y point)
   z (cl-transforms:z point)))

(defun points->point-cloud (pose points)
  (let ((pose-tf (cl-transforms:reference-transform pose)))
    (roslisp:make-msg
     "sensor_msgs/PointCloud"
     (stamp header) (tf:stamp pose)
     (frame_id header) (tf:frame-id pose)
     points (map 'vector
                 (lambda (p)
                   (roslisp:with-fields (x y z) p
                     (point->msg
                      (cl-transforms:transform-point
                       pose-tf (cl-transforms:make-3d-vector x y z))
                      "geometry_msgs/Point32")))
                 points))))

(defun cop-obj->point-cloud (desig)
  (let ((po (reference desig))
        (pose (designator-pose desig)))
    (declare (type perception-pm:cop-perceived-object po))
    (roslisp:with-fields ((type (type shape))
                          (vertices (vertices shape)))
        (roslisp:call-service "/cop_geometric_shape" 'vision_srvs-srv:cop_get_object_shape
                              :object_id (perception-pm:object-id po))
      (when (or (eql type 3) (eql type 4))
        (points->point-cloud pose vertices)))))

(defun cop-obj->graspable-obj (desig &optional (reference-frame "/base_footprint"))
  (let ((po (reference desig))
        (pose (designator-pose desig)))
    (declare (type perception-pm:cop-perceived-object po))
    (roslisp:with-fields ((type (type shape))
                          (vertices (vertices shape)))
        (roslisp:call-service "/cop_geometric_shape" 'vision_srvs-srv:cop_get_object_shape
                              :object_id (perception-pm:object-id po))
      (when (or (eql type 3) (eql type 4))
        (roslisp:make-msg
         "object_manipulation_msgs/GraspableObject"
         reference_frame_id reference-frame
         cluster (points->point-cloud pose vertices))))))