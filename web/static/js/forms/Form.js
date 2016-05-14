import _ from 'lodash';
import React from 'react';

import Fields from './fields';
import FieldContainer from './FieldContainer';

const EMAIL_REGEXP = /^(([^<>()\[\]\\.,;:\s@"]+(\.[^<>()\[\]\\.,;:\s@"]+)*)|(".+"))@((\[[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}])|(([a-zA-Z\-0-9]+\.)+[a-zA-Z]{2,}))$/;

class Form extends React.Component {
  constructor() {
    super();
    this.state = {
      value: {},
      errors: {},
    };
  }

  changeHandler(e) {
    var value = this.state.value;

    value[e.target.name] = e.target.value;

    if(this.props.validationEnabled) {
      this.validate(value);
    }
    this.setState({
      value: value,
    });
  }

  validate(value = this.state.value) {
    const errors = _.reduce(this.props.schema, (result, field, key) => {
      if(field.required && _.isEmpty(value[key])) {
        result[key] = 'This is a required field.';
      }
      else if(field.email && !EMAIL_REGEXP.test(value[key])) {
        result[key] = 'Enter a valid email.';
      }
      else if(field.minlength && value[key].length < field.minlength) {
        result[key] = `Must be at least ${field.minlength} character(s).`;
      }
      return result;
    }, {});

    this.setState({
      errors: errors,
    });
    return _.isEmpty(errors);
  }

  getValue() {
    return this.state.value;
  }

  render() {
    const fields = _.reduce(this.props.schema, (result, field, key) => {
      let element = Fields[field.field];

      if(element) {
        let errors = _.reduce(this.props.errors, (result, error) => {
          return {
            ...result,
            ...error,
          };
        }, this.state.errors);

        let fieldProps = {
          ...field,
          name: key,
          errorText: errors[key],
          onChange: this.changeHandler.bind(this),
        };

        result.push(
          <FieldContainer
            field={element}
            fieldProps={fieldProps}
          />
        );
      }
      return result;
    }, []);

    return (
      <div className='form'>
        { fields }
      </div>
    );
  }
}

Form.defaultProps = {
  validationEnabled: false,
  schema: {},
  errors: [],
};

export default Form;
