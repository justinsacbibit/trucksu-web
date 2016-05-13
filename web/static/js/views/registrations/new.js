import React, { PropTypes } from 'react';
import { connect } from 'react-redux';
import { Link } from 'react-router';

import Actions from '../../actions/registrations';
import logoImage from '../../../images/logo-transparent.png';
import { setDocumentTitle, renderErrorsFor } from '../../utils';

import Form from '../../forms/Form';
import SignupFormSchema from '../../forms/schemas/SignupFormSchema';

const RegistrationsNew = React.createClass({
  getInitialState() {
    return {
      validationEnabled: false
    };
  },
  componentDidMount() {
    setDocumentTitle('Sign up');
  },
  handleClickSubmit(e) {
    e.preventDefault();

    const { form } = this.refs;

    if(form.validate()) {
      const { dispatch } = this.props;
      const data = form.getValue();

      dispatch(Actions.signUp(data));
    }

    this.setState({
      validationEnabled: true
    });
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
        <div id='sign_up_form'>
          <Form
            ref='form'
            schema={SignupFormSchema}
            validationEnabled={this.state.validationEnabled}
          />
          <button onClick={this.handleClickSubmit}>Sign up</button>
        </div>
        <Link to='/sign_in'>Sign in</Link>
      </div>
    );
  }
});

const mapStateToProps = (state) => ({
  errors: state.registration.errors,
});

export default connect(mapStateToProps)(RegistrationsNew);