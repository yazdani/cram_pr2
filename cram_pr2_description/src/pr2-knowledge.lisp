;;; Copyright (c) 2012, Lorenz Moesenlechner <moesenle@in.tum.de>
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

(in-package :cram-pr2-description)


(defparameter *right-parking-end-effector-pose*
  (cl-transforms-stamped:make-pose-stamped
   "torso_lift_link" 0.0
   (cl-transforms:make-3d-vector 0.3 -0.3 -0.23)
   (cl-transforms:euler->quaternion :ay (/ pi 2))))

(defparameter *right-parking-joint-states*
  '(("r_shoulder_pan_joint" -1.3810115229719555d0)
    ("r_shoulder_lift_joint" 1.1282870348994702d0)
    ("r_upper_arm_roll_joint" -1.7100000000000002d0)
    ("r_elbow_flex_joint" -2.105735087282934d0)
    ("r_forearm_roll_joint" -2.658135473603226d0)
    ("r_wrist_flex_joint" -1.9927790883777252d0)
    ("r_wrist_roll_joint" -2.5861844605475843d0)))

(defparameter *left-parking-end-effector-pose*
  (cl-transforms-stamped:make-pose-stamped
   "torso_lift_link" 0.0
   (cl-transforms:make-3d-vector 0.3 0.3 -0.23)
   (cl-transforms:euler->quaternion :ay (/ pi 2))))

(defparameter *left-parking-joint-states*
  '(("l_shoulder_pan_joint" 1.3810115229719555d0)
    ("l_shoulder_lift_joint" 1.1282870348994702d0)
    ("l_upper_arm_roll_joint" 1.71d0)
    ("l_elbow_flex_joint" -2.105735087282934d0)
    ("l_forearm_roll_joint" 2.6581354736032257d0)
    ("l_wrist_flex_joint" -1.9927790883777252d0)
    ("l_wrist_roll_joint" 2.586184460547585d0)))

(def-grasp :top (cl-transforms:euler->quaternion :ay (/ pi -2)))
(def-grasp :left (cl-transforms:euler->quaternion :az (/ pi 2)) :side)
(def-grasp :right (cl-transforms:euler->quaternion :az (/ pi -2)) :side)
(def-grasp :front (cl-transforms:make-identity-rotation))

(def-tool (cl-transforms:make-3d-vector 1 0 0) 0.20)

(def-fact-group pr2-metadata (robot
                              robot-base-frame robot-torso-link-joint
                              robot-odom-frame
                              camera-frame camera-minimal-height camera-maximal-height
                              robot-pan-tilt-links robot-pan-tilt-joints
                              end-effector-link gripper-link gripper-joint
                              planning-group
                              robot-arms-parking-joint-states
                              end-effector-parking-pose
                              robot-pre-grasp-joint-states)
  (<- (robot pr2))

  (<- (robot-odom-frame pr2 "odom_combined"))

  (<- (robot-base-frame pr2 "base_footprint"))
  (<- (robot-torso-link-joint pr2 "torso_lift_link" "torso_lift_joint"))

  (<- (camera-frame pr2 "head_mount_kinect_rgb_optical_frame"))
  (<- (camera-frame pr2 "openni_rgb_optical_frame"))
  (<- (camera-frame pr2 "narrow_stereo_optical_frame"))
  (<- (camera-minimal-height pr2 1.27))
  (<- (camera-maximal-height pr2 1.60))
  (<- (robot-pan-tilt-links pr2 "head_pan_link" "head_tilt_link"))
  (<- (robot-pan-tilt-joints pr2 "head_pan_joint" "head_tilt_joint"))

  (<- (end-effector-link pr2 :left "l_wrist_roll_link"))
  (<- (end-effector-link pr2 :right "r_wrist_roll_link"))

  (<- (gripper-link pr2 :left ?link)
    (lisp-fun search "l_gripper" ?link ?pos)
    (lisp-pred identity ?pos))
  (<- (gripper-link pr2 :right ?link)
    (lisp-fun search "r_gripper" ?link ?pos)
    (lisp-pred identity ?pos))

  (<- (gripper-joint pr2 :left "l_gripper_joint"))
  (<- (gripper-joint pr2 :right "r_gripper_joint"))

  (<- (planning-group pr2 :left "left_arm"))
  (<- (planning-group pr2 :right "right_arm"))
  (<- (planning-group pr2 (:left :right) "both_arms"))
  (<- (planning-group pr2 (:right :left) "both_arms"))

  (<- (robot-arms-parking-joint-states pr2 ?joint-states)
    (symbol-value *right-parking-joint-states* ?right-joint-states)
    (symbol-value *left-parking-joint-states* ?left-joint-states)
    (append ?right-joint-states ?left-joint-states ?joint-states))

  (<- (robot-arms-parking-joint-states pr2 ?joint-states :left)
    (symbol-value *left-parking-joint-states* ?joint-states))

  (<- (robot-arms-parking-joint-states pr2 ?joint-states :right)
    (symbol-value *right-parking-joint-states* ?joint-states))

  (<- (end-effector-parking-pose pr2 ?pose :left)
    (symbol-value *left-parking-end-effector-pose* ?pose))

  (<- (end-effector-parking-pose pr2 ?pose :right)
    (symbol-value *right-parking-end-effector-pose* ?pose))

  (<- (robot-pre-grasp-joint-states
       pr2 (("torso_lift_joint" 0.33) . ?parking-joint-states))
    (robot-arms-parking-joint-states pr2 ?parking-joint-states))

  (<- (robot-pre-grasp-joint-states
       pr2 (("torso_lift_joint" 0.165) . ?parking-joint-states))
    (robot-arms-parking-joint-states pr2 ?parking-joint-states))

  (<- (robot-pre-grasp-joint-states
       pr2 (("torso_lift_joint" 0.00) . ?parking-joint-states))
    (robot-arms-parking-joint-states pr2 ?parking-joint-states)))

(def-fact-group pr2-manipulation-knowledge (grasp
                                            side
                                            arm
                                            object-type-grasp
                                            object-designator-grasp
                                            orientation-matters
                                            required-arms)
  (<- (grasp pr2 :top))
  (<- (grasp pr2 :side))
  (<- (grasp pr2 :front))

  (<- (side pr2 :right))
  (<- (side pr2 :left))

  (<- (arm pr2 ?arm)
    (side pr2 ?arm))

  (<- (object-type-grasp :mug ?grasp (?side))
    (grasp pr2 ?grasp)
    (side pr2 ?side))

  (<- (object-type-grasp :mondamin :front (?side))
    (side pr2 ?side))

  (<- (object-type-grasp :plate :side (:left :right)))

  (<- (object-type-grasp :pot :side (:left :right)))

  (<- (object-type-grasp :handle :front (?side))
    (side pr2 ?side))

  (<- (object-type-grasp ?type :top (?side))
    (member ?type (:cutlery :knife :fork :spatula))
    (side pr2 ?side))

  (<- (object-type-grip-maximum-effort pr2 :mug 50))
  (<- (object-type-grip-maximum-effort pr2 :mondamin 30))
  (<- (object-type-grip-maximum-effort pr2 :handle 50))

  (<- (object-designator-grasp ?object-designator ?grasp ?sides)
    (lisp-fun desig:current-desig ?object-designator ?current-object-designator)
    (desig:desig-prop ?current-object-designator (:type ?object-type))
    (object-type-grasp ?object-type ?grasp ?sides))

  (<- (orientation-matters ?object-designator)
    (lisp-fun desig:current-desig ?object-designator ?current-object-designator)
    (or (desig:desig-prop ?current-object-designator (:type :knife))
        (desig:desig-prop ?current-object-designator (:type :fork))
        (desig:desig-prop ?current-object-designator (:type :spatula))))

  (<- (required-arms ?object-designator ?arms)
    (desig:desig-prop ?object-designator (:type ?object-type))
    ;; object-type-grasp will give the cross-product of all available
    ;; arms and grasps. That's why we first calculate the set of all
    ;; solutions of arms (i.e. duplicate arms removed).
    (once
     (or
      (setof ?arms (object-type-grasp ?object-type ?_ ?arms) ?all-arms-solutions)
      (setof (?arm) (and (robot ?robot) (arm ?robot ?arm)) ?all-arms-solutions)))
    (member ?arms ?all-arms-solutions)))

(defmethod side->ik-group-name ((side symbol))
  (ecase side
    (:right "right_arm")
    (:left "left_arm")))
