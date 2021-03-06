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

(defpackage pr2-projection-process-modules
  (:nicknames #:projection-process-modules)
  (:use #:common-lisp
        #:cram-bullet-reasoning
        #:cram-process-modules
        #:cram-projection
        #:cl-transforms-stamped
        #:cram-robot-interfaces
        #:cram-tf)
  (:shadowing-import-from #:cram-bullet-reasoning name)
  (:shadowing-import-from #:cl-bullet pose)
  (:import-from #:cram-robot-interfaces arm trajectory-point end-effector-link robot)
  (:export execute-container-opened execute-container-closed
           execute-park execute-lift execute-grasp execute-put-down
           projection-navigation projection-ptu projection-perception
           projection-manipulation pr2-bullet-projection-environment
           action-started action-finished action-duration projection-role))

(defpackage projection-designators
  (:use #:common-lisp #:cram-designators #:cram-prolog
        #:projection-process-modules #:cram-robot-interfaces)
  (:import-from #:cram-process-modules
                matching-process-module available-process-module projection-running)
  (:import-from #:cram-projection *projection-environment*)
  (:export projection-role required-sides))
