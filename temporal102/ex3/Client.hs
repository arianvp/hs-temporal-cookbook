module Main where

import Control.Monad.Logger (defaultOutput, runStdoutLoggingT)
import Control.Monad.Trans.Reader (runReaderT)
import RequireCallStack (RequireCallStack, provideCallStack)
import System.IO (stdout)
import Temporal.Client (mkWorkflowClientConfig, workflowClient)
import Temporal.Client qualified as Client
import Temporal.Core.Client (connectClient, defaultClientConfig)
import Temporal.Runtime (TelemetryOptions (..), initializeRuntime)
import Temporal.TH (WorkflowFn, ActivityFn)
import Temporal.TH qualified
import Temporal.Worker qualified as Worker
import Temporal.Workflow (Workflow, WorkflowId (..))
import Temporal.Workflow qualified as Workflow
import UnliftIO.Exception (bracket)
import Workflow

taskQueue :: Workflow.TaskQueue
taskQueue = "pizza-tasks"

namespace :: Workflow.Namespace
namespace = "default"

main :: IO ()
main = do
  client <- mkClient

  let workflowId = WorkflowId $ "pizza-workflow-order-" <> (tshow testPizzaOrder.poOrderNumber)

  _result <-
    flip runReaderT client $
      Client.execute
        PizzaWorkflow
        workflowId
        (Client.startWorkflowOptions taskQueue)
        testPizzaOrder
  pure ()
  where
    mkClient = do
      runtime <- initializeRuntime NoTelemetry
      coreClient <- runStdoutLoggingT $ connectClient runtime defaultClientConfig
      workflowClient coreClient (mkWorkflowClientConfig namespace)

    testPizzaOrder :: PizzaOrder
    testPizzaOrder =
      let address = CustomerAddress "701 Mission Street" "Apartment 9C"
          largeVeg = Pizza "Large, with mushrooms and onions" 1500
          smallPep = Pizza "Small, with pepperoni" 1200
       in PizzaOrder address 31337 [largeVeg, smallPep]
