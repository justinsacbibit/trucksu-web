import React, { PropTypes } from 'react';
import { connect } from 'react-redux';
import { Link } from 'react-router';

import Actions from '../../actions/sessions';
import { setDocumentTitle } from '../../utils';
import logoImage from '../../../images/logo-transparent.png';

const SessionsNew = React.createClass({
  componentDidMount() {
    setDocumentTitle('Sign in');
  },

  handleClickSubmit(e) {
    e.preventDefault();

    const { username, password } = this.refs;
    const { dispatch } = this.props;

    dispatch(Actions.signIn(username.value, password.value));
  },

  renderError() {
    let { error } = this.props;

    if (!error) return false;

    return (
      <div className='general-error'>
        {error}
      </div>
    );
  },

  render() {
    return (
      <div className='auth_container'>
        <div className='logo'>
          <img src={logoImage} />
        </div>
        <form id='sign_in_form' onSubmit={this.handleClickSubmit}>
          { this.renderError() }
          <div className='field'>
            <input
              ref='username'
              type='text'
              id='user_username'
              placeholder='Username'
              defaultValue=''
              required={true}
            />
          </div>
          <div className='field'>
            <input
              ref='password'
              type='password'
              id='user_password'
              placeholder='Password'
              defaultValue=''
              required={true}
            />
          </div>
          <button type='submit'>Sign in</button>
        </form>
        <Link to='/sign_up'>Create new account</Link>
      </div>
    );
  }
});

const mapStateToProps = (state) => (
  state.session
);

export default connect(mapStateToProps)(SessionsNew);