public with sharing class QueryBuilder {
    public enum SortOrder {
        ASCEND,
        DESCEND
    }

    public enum NullsPosition {
        NULLSLAST,
        NULLSFIRST
    }

    public enum Condition {
        IS_IN,
        NOT_IN,
        EQUAL,
        NOT_EQUAL,
        IS_LIKE,
        LESS_THAN,
        LESS_THAN_EQUAL,
        GREATER_THAN,
        GREATER_THAN_EQUAL,
        EXCLUDES,
        INCLUDES
    }

    private static String conditionToString(Condition cond) {
        if (cond == Condition.IS_IN)
            return 'IN';
        if (cond == Condition.NOT_IN)
            return 'NOT IN';
        if (cond == Condition.EQUAL)
            return '=';
        if (cond == Condition.NOT_EQUAL)
            return '!=';
        if (cond == Condition.IS_LIKE)
            return 'LIKE';
        if (cond == Condition.LESS_THAN)
            return '<';
        if (cond == Condition.LESS_THAN_EQUAL)
            return '<=';
        if (cond == Condition.GREATER_THAN)
            return '>';
        if (cond == Condition.GREATER_THAN_EQUAL)
            return '>=';
        if (cond == Condition.EXCLUDES)
            return 'EXCLUDES';
        if (cond == Condition.INCLUDES)
            return 'INCLUDES';
        return null;
    }

    public static Map<String, SortOrder> orderByOrderString = new Map<String, SortOrder>{
        'asc' => SortOrder.ASCEND,
        'desc' => SortOrder.DESCEND
    };
    
    public virtual class FilterClause {
        public String          fieldName;
    }

    /* Use this if you want to use a subquery in an IN where clause */
    public class QueryFilterClause extends filterClause {
        QueryBuilder query;
        String fieldName;
        Condition condition;

        public QueryFilterClause(String fName, Condition c, QueryBuilder q) {
            query = q;
            fieldName = fName;
            condition = c;
        }

        public override String toString() {
           return fieldName + ' ' + conditionToString(condition) + ' (' + query.toString() + ')';
        }
    }

    public class LikeFilterClause extends FilterClause {
        private String pattern;
        
        public LikeFilterClause(String fName, String ptrn) {
            fieldName = fName;
            pattern = ptrn;
        }

        public override String toString() {
            return fieldName + ' LIKE \'' + pattern + '\'';
        }
    }

    public class StringFilterClause extends FilterClause {
        Set<String>     filterValues;
        Boolean         negateFilter = false;

        public StringFilterClause(String fName, Set<String> vals, Boolean negate) {
            fieldName = fName;
            filterValues = vals;
            negateFilter = negate;
        }

        public StringFilterClause(String fname, String val, Boolean negate) {
            this(fname, new Set<String>{val}, negate);
        }

        public StringFilterClause(String fName, Set<String> vals) {
            this(fName, vals, false);
        }

        public StringFilterClause(String fname, String val) {
            this(fname, new Set<String>{val});
        }

        public override String toString() {
            String filterClause = fieldName + ((negateFilter)? ' NOT IN ': ' IN ') + '(';

            Set<String> vals = new Set<String>();
            for (String val: filterValues) {
                vals.add('\'' + val + '\'');
            }
            filterClause += String.join(vals, ',') + ')';
            return filterClause;
        }
    }

    public class IntegerFilterClause extends FilterClause {
        List<Integer>    filterValues;

        public IntegerFilterClause(String fName, List<Integer> vals) {
            fieldName = fName;
            filterValues = vals;
        }

        public IntegerFilterClause(String fname, Integer val) {
            this(fname, new List<Integer>{val});
        }

        public override String toString() {
            String filterClause = fieldName + ' IN ' + '(' + String.join(filterValues, ',') + ')';
            
            return filterClause;
        }
    }

    public class BooleanFilterClause extends FilterClause {
        Boolean filterValue;
        Condition condition = QueryBuilder.Condition.EQUAL;

        public BooleanFilterClause(String fName, Boolean val) {
            fieldName = fName;
            filterValue = val;
        }

        public BooleanFilterClause(String fName, Condition c, Boolean val) {
            fieldName = fName;
            filterValue = val;
            condition = c;
        }

        public override String toString() {
            String filterClause = fieldName + conditionToString(condition) + filterValue;

            return filterClause;
        }
    }

    public class OrderClause {
        private String          fieldName;
        private SortOrder       sortOrder;
        private NullsPosition   nullsPos;
        
            {
                sortOrder = QueryBuilder.SortOrder.ASCEND;
                nullsPos = NullsPosition.NULLSFIRST;
            }

        public OrderClause(String fName) {
            fieldName = fName;
        }

        public OrderClause(String fName, SortOrder sOrder) {
            fieldName = fName;
            sortOrder = sOrder;
            if (sortOrder == QueryBuilder.SortOrder.DESCEND) {
                nullsPos = NullsPosition.NULLSLAST;
            }
        }

        public OrderClause(String fName, String sOrder) {
            fieldName = fName;
            sortOrder = orderByOrderString.get(sOrder);
            if (sortOrder == QueryBuilder.SortOrder.DESCEND) {
                nullsPos = NullsPosition.NULLSLAST;
            }
        }

        public OrderClause(String fName, SortOrder sOrder,
        NullsPosition nsPos) {
            fieldName = fName;
            sortOrder = sOrder;
            nullsPos = nsPos;
        }

        public OrderClause(String fName, String sOrder,
        NullsPosition nsPos) {
            fieldName = fName;
            sortOrder = orderByOrderString.get(sOrder);
            nullsPos = nsPos;
        }

        public override String      toString() {
            /* returns string like: [field name] [order] [nullsclause] */
            String orderClause = fieldName;

            if (sortOrder == QueryBuilder.SortOrder.ASCEND) {
                orderClause += ' ASC';
            } else {
                orderClause += ' DESC';
            }
            
            if (nullsPos == NullsPosition.NULLSFIRST) {
                orderClause += ' NULLS FIRST';
            } else {
                orderClause += ' NULLS LAST';
            }

            return orderClause;
        }
    }

    private Set<String>                 selectFields;
    private String                      tableName;
    private List<FilterClause>          filterClauses;
    private List<OrderClause>           orderByClauses;
    private String                      securityClause = 'WITH USERMODE';
    private Integer                     numRecords = -1;

    public QueryBuilder(Set<String> sFields, String tName, List<OrderClause> 
    orderClauses) {
        selectFields = sFields;
        tableName = tName;
        filterClauses = new List<FilterClause>();
        orderByClauses = orderClauses;
    }

    public QueryBuilder(Set<String> sFields, String tName, List<FilterClause> 
    filters) {
        selectFields = sFields;
        tableName = tName;
        filterClauses = filters;
        orderByClauses = new List<OrderClause>();
    }

    public QueryBuilder(Set<String> sFields, String tName, FilterClause filter) {
        selectFields = sFields;
        tableName = tName;
        filterClauses = new List<FilterClause>{filter};
        orderByClauses = new List<OrderClause>();
    }

    public QueryBuilder(Set<String> sFields, String tName, List<FilterClause> 
    filters, List<OrderClause> orderClauses) {
        selectFields = sFields;
        tableName = tName;
        filterClauses = filters;
        orderByClauses = orderClauses;
    }

    public QueryBuilder(Set<String> sFields, String tName) {
        tableName = tName;
        selectFields = sFields;
        filterClauses = new List<FilterClause>();
        orderByClauses = new List<OrderClause>();
    }

    // public QueryBuilder(List<String> sFields, String tName) {
    //     tableName = tName;
    //     selectFields = new Set<String>();
    //     selectFields.addAll(sFields);
    //     filterClauses = new List<FilterClause>();
    //     orderByClauses = new List<OrderClause>();
    // }

    public QueryBuilder(String tName) {
        tableName = tName;
        selectFields = new Set<String>();
        filterClauses = new List<FilterClause>();
        orderByClauses = new List<OrderClause>();
    }

    public void     setLimit(Integer lim) {
        numRecords = lim;
    }

    public void    addSelectField(String field) {
        selectFields.add(field);
    }

    public void    addFilterClause(FilterClause fc) {
        filterClauses.add(fc);
    }

    public void    setFilterClauses(List<FilterClause> fcs) {
        filterClauses = fcs;
    }

    public void    addOrderClause(OrderClause oc) {
        orderByClauses.add(oc);
    }

    public void    resetOrderClause() {
        orderByClauses = new List<OrderClause>();
    }

    void    resetFilterClause() {
        filterClauses = new List<FilterClause>();
    }

    public String      toString(Boolean asUser) {
        Set<String>    clauses = new Set<String>();
        String          selectClause = 
        'SELECT ' + String.join(selectFields, ',') + '\n' + 'FROM ' + tableName;
        
        clauses.add(selectClause);
        if (filterClauses != null && filterClauses.size() > 0) {
            String filterClauseString = 'WHERE ';
            Set<String> filterClauseStrings = new Set<String>();

            for (FilterClause clause: filterClauses) {
                filterClauseStrings.add(clause.toString());
            }
            clauses.add(filterClauseString + String.join(filterClauseStrings, ' AND '));
        }
        if (asUser) {
            clauses.add(securityClause);
        }
        if (orderByClauses != null && orderByClauses.size() > 0) {
            String orderByString = 'ORDER BY ';

            Set<String> orderClauseStrings = new Set<String>();
            for (OrderClause clause: orderByClauses) {
                orderClauseStrings.add(clause.toString());
            }
            clauses.add(orderByString + String.join(orderClauseStrings, ','));
        }
        if (numRecords != -1) {
            clauses.add('LIMIT ' + String.valueOf(numRecords));
        }
        // System.debug(String.join(clauses, '\n'));
        return String.join(clauses, '\n');
    }

    public override String   toString() {
        return toString(false);
    }
}