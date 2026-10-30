WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        RANK() OVER (PARTITION BY p.p_partkey ORDER BY s.s_acctbal DESC) AS rnk
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
),
RecentOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_custkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        l.l_shipdate >= cast('1998-10-01' as date) - INTERVAL '1 year'
    GROUP BY 
        o.o_orderkey, o.o_custkey
),
HighValueCustomers AS (
    SELECT 
        c.c_custkey, 
        c.c_name,
        SUM(ro.total_revenue) AS total_spent
    FROM 
        customer c
    JOIN 
        RecentOrders ro ON c.c_custkey = ro.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
    HAVING 
        SUM(ro.total_revenue) > 10000
)
SELECT 
    hv.c_custkey,
    hv.c_name,
    COUNT(DISTINCT rs.s_suppkey) AS supplier_count,
    AVG(s.s_acctbal) AS avg_acct_balance,
    MAX(rs.rnk) AS top_supplier_rank,
    COALESCE((SELECT COUNT(DISTINCT l.l_orderkey)
              FROM lineitem l
              WHERE l.l_returnflag = 'R' AND l.l_shipdate >= cast('1998-10-01' as date) - INTERVAL '1 year'), 0) AS return_order_count
FROM 
    HighValueCustomers hv
LEFT JOIN 
    RankedSuppliers rs ON hv.c_custkey = rs.s_suppkey
LEFT JOIN 
    supplier s ON rs.s_suppkey = s.s_suppkey
GROUP BY 
    hv.c_custkey, hv.c_name
HAVING 
    COUNT(DISTINCT rs.s_suppkey) > 2
ORDER BY 
    avg_acct_balance DESC;