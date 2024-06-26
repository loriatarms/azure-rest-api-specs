import "@azure-tools/typespec-azure-core";
import "@typespec/rest";
import "./models.tsp";
import "../shared/routes.tsp";

using Azure.Core;
using TypeSpec.Rest;
using TypeSpec.Http;

namespace DevCenterService;

interface DevBoxesOperations {
  @doc("Lists available pools")
  listPools is StandardResourceOperations.ResourceList<Pool>;

  @doc("Gets a pool")
  getPool is StandardResourceOperations.ResourceRead<Pool>;

  @doc("Lists available schedules for a pool.")
  listSchedules is StandardResourceOperations.ResourceList<Schedule>;

  @doc("Gets a schedule.")
  getSchedule is StandardResourceOperations.ResourceRead<Schedule>;

  #suppress "@azure-tools/typespec-azure-core/use-standard-operations" "Need of reuse DevBoxListResult"
  // This does fit in the ResourceList<DevBox> but since there are three different operations that returns dev box list result,
  // we can't use the standard operation here - it would not allow the use of DevBoxListResult in the other operations.
  // error when using it in other operations: duplicate-type-name 'PagedDevBox' (model DevBoxListResult)
  @doc("Lists Dev Boxes in the project for a particular user.")
  @route("/projects/{projectName}/users/{userId}/devboxes")
  @get
  listDevBoxes is Azure.Core.Foundations.Operation<
    {
      @doc("The DevCenter Project upon which to execute operations.")
      @path
      projectName: string;

      @doc("The AAD object id of the user. If value is 'me', the identity is taken from the authentication context.")
      @path
      userId: string;
    },
    DevBoxListResult
  >;

  @doc("Gets a Dev Box")
  getDevBox is StandardResourceOperations.ResourceRead<DevBox>;

  #suppress "@azure-tools/typespec-azure-core/use-standard-operations" "Standard operations produce wrong swagger"
  // The standard operation names the body as resource, so the generated swagger has parameter
  //  {
  //     "name": "resource",
  //     "in": "body",
  //  },
  // instead of the desired
  //  {
  //     "name": "body",
  //     "in": "body",
  //  }
  @doc("Creates or replaces a Dev Box.")
  @finalOperation(DevBoxesOperations.getDevBox)
  @pollingOperation(SharedOperations.getProjectOperationStatus)
  @route("/projects/{projectName}/users/{userId}/devboxes/{devBoxName}")
  @put
  createDevBox is Azure.Core.Foundations.Operation<
    {
      @doc("The DevCenter Project upon which to execute the operation.")
      @path
      projectName: string;

      @doc("The AAD object id of the user. If value is 'me', the identity is taken from the authentication context.")
      @path
      userId: string;

      @doc("The name of a Dev Box.")
      @path
      devBoxName: string;

      @doc("Represents the body request of a Dev Box creation. Dev Box Pool name is required. Optionally set the owner of the Dev Box as local administrator")
      @body
      body: DevBox;
    },
    DevBox | {
      @statusCode statusCode: 201;

      @header("Location")
      location: ResourceLocation<DevBox>;

      @pollingLocation
      @header("Operation-Location")
      operationLocation: string;

      @body body?: DevBox;
    }
  >;

  #suppress "@azure-tools/typespec-azure-core/use-standard-operations" "Does not fit any standard operation pattern"
  //Can not use LongRunningResourceDelete because response is 202 or error, but we also accept 204 response"
  @doc("Deletes a Dev Box.")
  @pollingOperation(SharedOperations.getProjectOperationStatus)
  @route("/projects/{projectName}/users/{userId}/devboxes/{devBoxName}")
  @delete
  deleteDevBox is Azure.Core.Foundations.Operation<
    {
      @doc("The DevCenter Project upon which to execute operations.")
      @path
      projectName: string;

      @doc("The AAD object id of the user. If value is 'me', the identity is taken from the authentication context.")
      @path
      userId: string;

      @doc("The name of a Dev Box.")
      @path
      devBoxName: string;
    },
    {
      @statusCode statusCode: 202;

      @header("Location")
      location: string;

      @pollingLocation
      @header("Operation-Location")
      operationLocation: string;

      @body body: OperationStatus;
    } | {
      @statusCode statusCode: 204;
    }
  >;

  @doc("Starts a Dev Box")
  @pollingOperation(SharedOperations.getProjectOperationStatus)
  @action("start")
  startDevBox is StandardResourceOperations.LongRunningResourceAction<
    DevBox,
    {},
    {
      @statusCode
      statusCode: 202;

      @body
      body: OperationStatus;
    }
  >;

  @doc("Stops a Dev Box")
  @pollingOperation(SharedOperations.getProjectOperationStatus)
  @action("stop")
  stopDevBox is StandardResourceOperations.LongRunningResourceAction<
    DevBox,
    {
      @doc("Optional parameter to hibernate the dev box.")
      @query
      hibernate?: boolean;
    },
    {
      @statusCode
      statusCode: 202;

      @body
      body: OperationStatus;
    }
  >;

  @doc("Restarts a Dev Box")
  @pollingOperation(SharedOperations.getProjectOperationStatus)
  @action("restart")
  restartDevBox is StandardResourceOperations.LongRunningResourceAction<
    DevBox,
    {},
    {
      @statusCode
      statusCode: 202;

      @body
      body: OperationStatus;
    }
  >;

  #suppress "@azure-tools/typespec-azure-core/use-standard-operations" "can not be represeted by using stand operations"
  //There is no @key for RemoteConnection model
  @doc("Gets RDP Connection info")
  @route("/projects/{projectName}/users/{userId}/devboxes/{devBoxName}/remoteConnection")
  @get
  getRemoteConnection is Azure.Core.Foundations.Operation<
    {
      @doc("The DevCenter Project upon which to execute operations.")
      @path
      projectName: string;

      @doc("The AAD object id of the user. If value is 'me', the identity is taken from the authentication context.")
      @path
      userId: string;

      @doc("The name of a Dev Box.")
      @path
      devBoxName: string;
    },
    RemoteConnection
  >;

  @doc("Lists actions on a Dev Box.")
  listDevBoxActions is StandardResourceOperations.ResourceList<DevBoxAction>;

  @doc("Gets an action.")
  getDevBoxAction is StandardResourceOperations.ResourceRead<DevBoxAction>;

  @doc("Skips an occurrence of an action.")
  @action("skip")
  skipAction is StandardResourceOperations.ResourceAction<
    DevBoxAction,
    {},
    NoContentResponse
  >;

  @doc("Delays the occurrence of an action.")
  @action("delay")
  delayAction is StandardResourceOperations.ResourceAction<
    DevBoxAction,
    {
      @doc("The time to delay the Dev Box action or actions until.")
      @query("until")
      delayUntil: utcDateTime;
    },
    DevBoxAction
  >;

  @doc("Delays all actions.")
  @action("delay")
  delayAllActions is StandardResourceOperations.ResourceCollectionAction<
    DevBoxAction,
    {
      @doc("The time to delay the Dev Box action or actions until.")
      @query("until")
      delayUntil: utcDateTime;
    },
    DevBoxActionsDelayMultipleResult
  >;
}

interface DevBoxesDevCenter {
  #suppress "@azure-tools/typespec-azure-core/use-standard-operations" "Does not fit any standard operation pattern since DevBox has a different path"
  @doc("Lists Dev Boxes that the caller has access to in the DevCenter.")
  @route("/devboxes")
  @get
  listAllDevBoxes is Azure.Core.Foundations.Operation<{}, DevBoxListResult>;

  #suppress "@azure-tools/typespec-azure-core/use-standard-operations" "Does not fit any standard operation pattern since DevBox has a different path"
  @doc("Lists Dev Boxes in the Dev Center for a particular user.")
  @route("/users/{userId}/devboxes")
  @get
  listAllDevBoxesByUser is Azure.Core.Foundations.Operation<
    {
      @doc("The AAD object id of the user. If value is 'me', the identity is taken from the authentication context.")
      @path
      userId: string;
    },
    DevBoxListResult
  >;
}
