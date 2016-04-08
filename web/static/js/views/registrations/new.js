import React, {PropTypes}   from 'react';
import { connect }          from 'react-redux';
import { Link }             from 'react-router';

import { setDocumentTitle, renderErrorsFor } from '../../utils';
import Actions              from '../../actions/registrations';

class RegistrationsNew extends React.Component {
  componentDidMount() {
    setDocumentTitle('Sign up');
  }

  _handleSubmit(e) {
    e.preventDefault();

    const { dispatch } = this.props;

    const data = {
      username: this.refs.username.value,
      email: this.refs.email.value,
      password: this.refs.password.value,
      password_confirmation: this.refs.passwordConfirmation.value,
    };

    dispatch(Actions.signUp(data));
  }

  render() {
    const { errors } = this.props;

    return (
      <div className='view-container registrations new'>
        <main>
          <header>
            <div className='logo' />
          </header>
          <form id='sign_up_form' onSubmit={::this._handleSubmit}>
            <div className='field'>
              <input ref='username' id='user_username' type='text' placeholder='Username' required={true} />
              {renderErrorsFor(errors, 'username')}
            </div>
            <div className='field'>
              <input ref='email' id='user_email' type='email' placeholder='Email' required={true} />
              {renderErrorsFor(errors, 'email')}
            </div>
            <div className='field'>
              <input ref='password' id='user_password' type='password' placeholder='Password' required={true} />
              {renderErrorsFor(errors, 'password')}
            </div>
            <div className='field'>
              <input ref='passwordConfirmation' id='user_password_confirmation' type='password' placeholder='Confirm password' required={true} />
              {renderErrorsFor(errors, 'password_confirmation')}
            </div>
            <button type='submit'>Sign up</button>
          </form>
          <Link to='/sign_in'>Sign in</Link>
        </main>
      </div>
    );
  }
}

const mapStateToProps = (state) => ({
  errors: state.registration.errors,
});

export default connect(mapStateToProps)(RegistrationsNew);
