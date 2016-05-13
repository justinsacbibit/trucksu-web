import Constants from '../constants';
import { httpGet, httpPost }  from '../utils';

const Actions = {
  fetchUser: (userId) => {
    return dispatch => {
      dispatch({ type: Constants.USER_FETCHING });

      httpGet(`/api/v1/user/${userId}`)
      .then((data) => {
        dispatch({
          type: Constants.USER_RECEIVED,
          user: data,
        });
      });
    };
  },
};

export default Actions;
