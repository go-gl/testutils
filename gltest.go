package gltest

import (
	"log"
	"runtime"

	"github.com/go-gl/gl"
	"github.com/go-gl/glfw"
)

var main_thread_work = make(chan func())
var main_thread_work_done = make(chan bool)

func OnTheMainThread(setup, after func()) {
	main_thread_work <- setup
	main_thread_work <- after
	<-main_thread_work_done
}

func init() {
	go func() {
		runtime.LockOSThread()

		if err := glfw.Init(); err != nil {
			log.Panic("glfw Error:", err)
		}

		w, h := 100, 100
		err := glfw.OpenWindow(w, h, 0, 0, 0, 0, 0, 0, glfw.Windowed)
		if err != nil {
			log.Panic("Error:", err)
		}

		if gl.Init() != 0 {
			log.Panic("gl error")
		}

		glfw.SetWindowSizeCallback(Reshape)
		glfw.SwapBuffers()

		for {
			(<-main_thread_work)()
			glfw.SwapBuffers()
			(<-main_thread_work)()
			main_thread_work_done <- true
		}

	}()
}

func SetWindowSize(width, height int) {
	glfw.SetWindowSize(width, height)
	// Need to wait for the reshape event, otherwise it happens at an arbitrary
	// point in the future (some unknown number of SwapBuffers())
	glfw.WaitEvents()
}

func Reshape(width, height int) {
	gl.Viewport(0, 0, width, height)

	gl.MatrixMode(gl.PROJECTION)
	gl.LoadIdentity()
	gl.Ortho(-1, 1, -1, 1, -1, 1)
	//gl.Ortho(-2.1, 6.1, -2.25*2, 2.1*2, -1, 1) // Y debug

	gl.MatrixMode(gl.MODELVIEW)
	gl.LoadIdentity()

	gl.ClearColor(0, 0, 0, 1)
	gl.Clear(gl.COLOR_BUFFER_BIT | gl.DEPTH_BUFFER_BIT)
}
