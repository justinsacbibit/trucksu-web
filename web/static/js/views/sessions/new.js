import { Paper, RaisedButton } from 'material-ui';
import React, { PropTypes } from 'react';
import { connect } from 'react-redux';
import { Link } from 'react-router';

import Actions from '../../actions/sessions';
import { setDocumentTitle } from '../../utils';

import Form from '../../forms/Form';
import SigninFormSchema from '../../forms/schemas/SigninFormSchema';
import logoImage from '../../../images/logo-transparent.png';

const SessionsNew = React.createClass({
  getInitialState() {
    return {
      validationEnabled: false
    };
  },
  componentDidMount() {
    setDocumentTitle('Sign in');
  },
  handleClickSubmit(e) {
    e.preventDefault();

    const { form } = this.refs;

    if(form.validate()) {
      const { username, password } = form.getValue();
      const { dispatch } = this.props;

      dispatch(Actions.signIn(username, password));
    }

    this.setState({
      validationEnabled: true
    });
  },
  renderError() {
    let { error } = this.props;

    if (!error) return false;
    return (
      <div className='error'>
        {error}
      </div>
    );
  },
  render() {
    return (
      <div id='auth_container'>
        <div className='logo'>
          <img src={logoImage} />
        </div>
        <form id='auth_form'>
          <h2>Sign In</h2>
          { this.renderError() }
          <Form
            ref='form'
            schema={SigninFormSchema}
            validationEnabled={this.state.validationEnabled}
          />
          <RaisedButton
            label='Sign In'
            type='submit'
            primary={true}
            onClick={this.handleClickSubmit}
          />
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