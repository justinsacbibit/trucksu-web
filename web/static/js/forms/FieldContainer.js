import React from 'react';

class FieldContainer extends React.Component {
  render() {
    const { field, fieldProps } = this.props;

    return (
      <div className='field' key={`field_${fieldProps.name}`}>
        { React.createElement(field, fieldProps) }
      </div>
    );
  }
}

export default FieldContainer;
