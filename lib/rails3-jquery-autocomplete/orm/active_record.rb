module Rails3JQueryAutocomplete
  module Orm
    module ActiveRecord
      def get_autocomplete_order(method, options, model=nil)
        order = options[:order]

        table_prefix = model ? "#{model.table_name}." : ""
        order || "#{table_prefix}#{method} ASC"
      end

      def get_autocomplete_items(parameters)
        model = parameters[:model]
        term = parameters[:term]
        method = parameters[:method]
        options = parameters[:options]
        scopes = Array(options[:scopes])
        where = options[:where]
        limit = get_autocomplete_limit(options)
        order = get_autocomplete_order(method, options, model)
        items = model.scoped

        scopes.each { |scope| items = items.send(scope) } unless scopes.empty?

        items = items.select(get_autocomplete_select_clause(model, method, options)) unless options[:full_model]
        items = items.where(get_autocomplete_where_clause(model, term, method, options)).
            limit(limit).order(order)
        items = items.where(where) unless where.blank?

        items
      end

      def get_autocomplete_select_clause(model, method, options)
        table_name = model.table_name
        columns = options[:search_columns].is_a?(Array) ? options[:search_columns] : [method]
        columns = columns.map {|column_name| "#{table_name}.#{column_name}"}
        extra_columns = (options[:extra_data].blank? ? [] : options[:extra_data])
        (["#{table_name}.#{model.primary_key}"] + columns + extra_columns)
      end

      def get_autocomplete_where_clause(model, term, method, options)
        table_name = model.table_name
        query = "#{(options[:full] ? '%' : '')}#{term.downcase}%"
        like_clause = (postgres? ? 'ILIKE' : 'LIKE')

        columns = options[:search_columns].is_a?(Array) ? options[:search_columns] : [method]
        where = columns.map {|column_name| "LOWER(#{table_name}.#{column_name}) #{like_clause} :q"}
        [where.join(" OR "), :q => query]
      end

      def postgres?
        defined?(PGconn)
      end
    end
  end
end