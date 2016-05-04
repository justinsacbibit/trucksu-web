import React, { PropTypes } from 'react';
import { connect } from 'react-redux';
import { Link } from 'react-router';

import Actions from '../../actions/registrations';
import logoImage from '../../../images/logo-transparent.png';
import { setDocumentTitle, renderErrorsFor } from '../../utils';

const RegistrationsNew = React.createClass({
  componentDidMount() {
    setDocumentTitle('Sign up');
  },

  handleClickSubmit(e) {
    e.preventDefault();

    const { username, email, password, passwordConfirmation } = this.refs;
    const { dispatch } = this.props;

    const data = {
      username: username.value,
      email: email.value,
      password: password.value,
      password_confirmation: passwordConfirmation.value,
    };

    dispatch(Actions.signUp(data));
  },

  render() {
    const errors = this.props.errors || [];
    const errKeys = errors.reduce((result, error) => {
      for(let key in error) {
        result.push(key);
      }
      return result;
    }, []);

    return (
      <div className='auth_container'>
        <div className='logo'>
          <img src={logoImage} />
        </div>
        <form id='sign_up_form' onSubmit={this.handleClickSubmit}>
          <div className='field'>
            <input
              ref='username'
              id='user_username'
              className={errKeys.includes('username') ? 'invalid' : ''}
              type='text'
              placeholder='Username'
              required={true}
            />
            { renderErrorsFor(errors, 'username') }
          </div>
          <div className='field'>
            <input
              ref='email'
              id='user_email'
              className={errKeys.includes('email') ? 'invalid' : ''}
              type='email'
              placeholder='Email'
              required={true}
            />
            { renderErrorsFor(errors, 'email') }
          </div>
          <div className='field'>
            <input
              ref='password'
              id='user_password'
              className={errKeys.includes('password') ? 'invalid' : ''}
              type='password'
              placeholder='Password'
              required={true}
            />
            { renderErrorsFor(errors, 'password') }
          </div>
          <div className='field'>
            <input
              ref='passwordConfirmation'
              id='user_password_confirmation'
              className={errKeys.includes('password_confirmation') ? 'invalid' : ''}
              type='password'
              placeholder='Confirm password'
              required={true}
            />
            { renderErrorsFor(errors, 'password_confirmation') }
          </div>
          <button type='submit'>Sign up</button>
        </form>
        <Link to='/sign_in'>Sign in</Link>
      </div>
    );
  }
});

const mapStateToProps = (state) => ({
  errors: state.registration.errors,
});

export default connect(mapStateToProps)(RegistrationsNew);