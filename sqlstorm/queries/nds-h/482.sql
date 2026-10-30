WITH SupplierSummary AS (
    SELECT 
        s.s_nationkey,
        COUNT(DISTINCT s.s_suppkey) AS total_suppliers,
        SUM(s.s_acctbal) AS total_account_balance
    FROM 
        supplier s
    GROUP BY 
        s.s_nationkey
),
NationDetails AS (
    SELECT 
        n.n_nationkey,
        n.n_name,
        r.r_name AS region_name,
        COALESCE(ss.total_suppliers, 0) AS total_suppliers,
        COALESCE(ss.total_account_balance, 0) AS total_account_balance
    FROM 
        nation n
    LEFT JOIN region r ON n.n_regionkey = r.r_regionkey
    LEFT JOIN SupplierSummary ss ON n.n_nationkey = ss.s_nationkey
),
HighValueOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_custkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_order_value
    FROM 
        orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        l.l_returnflag = 'N'
    GROUP BY 
        o.o_orderkey, o.o_custkey
    HAVING 
        SUM(l.l_extendedprice * (1 - l.l_discount)) > 10000
),
CustomerOrderCount AS (
    SELECT 
        c.c_custkey, 
        COUNT(o.o_orderkey) AS order_count
    FROM 
        customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey
)
SELECT 
    n.n_name,
    n.region_name,
    n.total_suppliers,
    n.total_account_balance,
    COALESCE(c.order_count, 0) AS customer_order_count,
    COALESCE(h.total_order_value, 0) AS high_value_order_value
FROM 
    NationDetails n
LEFT JOIN CustomerOrderCount c ON n.n_nationkey = c.c_custkey
LEFT JOIN HighValueOrders h ON c.c_custkey = h.o_custkey
WHERE 
    n.total_account_balance > 50000
ORDER BY 
    n.total_suppliers DESC, n.n_name
LIMIT 10;
