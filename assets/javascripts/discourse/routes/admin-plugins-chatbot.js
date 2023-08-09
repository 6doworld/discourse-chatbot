import DiscourseRoute from "discourse/routes/discourse";
import { ajax } from "discourse/lib/ajax";
import { popupAjaxError } from "discourse/lib/ajax-error";

export default class PluginsChatbotRoute extends DiscourseRoute {
  model() {
    if (!this.currentUser?.admin) {
      return { model: null };
    }

    return ajax("/chatbot/admin/statistics.json")
      .then((model) => {
        return model;
      })
      .catch(popupAjaxError);
  }
}
