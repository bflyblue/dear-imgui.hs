{-# language BlockArguments #-}
{-# language LambdaCase #-}
{-# language OverloadedStrings #-}

module Main ( main ) where

import Control.Exception
import Control.Monad
import Control.Monad.IO.Class
import Control.Monad.Managed
import DearImGui
import DearImGui.OpenGL3
import DearImGui.GLFW
import DearImGui.GLFW.OpenGL
import Graphics.GL
import Graphics.UI.GLFW (Window)
import qualified Graphics.UI.GLFW as GLFW

main :: IO ()
main = do
  initialised <- GLFW.init
  unless initialised $ error "GLFW init failed"

  runManaged $ do
    liftIO $ do
      GLFW.windowHint (GLFW.WindowHint'ClientAPI              GLFW.ClientAPI'OpenGL)
      GLFW.windowHint (GLFW.WindowHint'ContextVersionMajor    3)
      GLFW.windowHint (GLFW.WindowHint'ContextVersionMinor    2)
      GLFW.windowHint (GLFW.WindowHint'OpenGLProfile          GLFW.OpenGLProfile'Core)
      GLFW.windowHint (GLFW.WindowHint'OpenGLForwardCompat    True)
      GLFW.windowHint (GLFW.WindowHint'sRGBCapable            True)
      GLFW.windowHint (GLFW.WindowHint'Samples                (Just 4))
    mwin <- managed $ bracket
      (GLFW.createWindow 800 600 "Hello, Dear ImGui!" Nothing Nothing)
      (maybe (return ()) GLFW.destroyWindow)
    case mwin of
      Just win -> do
        liftIO $ do
          GLFW.makeContextCurrent (Just win)
          GLFW.swapInterval 1

        -- Create an ImGui context
        _ <- managed $ bracket createContext destroyContext

        -- Initialize ImGui's GLFW backend
        _ <- managed_ $ bracket_ (glfwInitForOpenGL win True) glfwShutdown

        -- Initialize ImGui's OpenGL backend
        _ <- managed_ $ bracket_ openGL3Init openGL3Shutdown

        liftIO $ mainLoop win
      Nothing -> do
        error "GLFW createWindow failed"

  GLFW.terminate

mainLoop :: Window -> IO ()
mainLoop win = do
  -- Process the event loop
  GLFW.pollEvents
  close <- GLFW.windowShouldClose win
  unless close do

    -- Tell ImGui we're starting a new frame
    openGL3NewFrame
    glfwNewFrame
    newFrame

    -- Build the GUI
    bracket_ (begin "Hello, ImGui!") end do
      -- Add a text widget
      text "Hello, ImGui!"

      -- Add a button widget, and call 'putStrLn' when it's clicked
      button "Clickety Click" >>= \case
        False -> return ()
        True  -> putStrLn "Ow!"

    -- Show the ImGui demo window
    showDemoWindow

    -- Render
    glClear GL_COLOR_BUFFER_BIT

    render
    openGL3RenderDrawData =<< getDrawData

    GLFW.swapBuffers win

    mainLoop win