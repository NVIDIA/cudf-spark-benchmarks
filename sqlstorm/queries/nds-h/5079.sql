WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        n.n_name AS nation_name,
        ROW_NUMBER() OVER (PARTITION BY n.n_nationkey ORDER BY s.s_acctbal DESC) AS rank
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
),
TopSuppliers AS (
    SELECT 
        rs.s_suppkey,
        rs.s_name,
        rs.s_acctbal,
        rs.nation_name
    FROM 
        RankedSuppliers rs
    WHERE 
        rs.rank <= 5
),
AggregateStats AS (
    SELECT 
        COUNT(DISTINCT c.c_custkey) AS total_customers,
        SUM(o.o_totalprice) AS total_revenue,
        AVG(o.o_totalprice) AS avg_order_value,
        COUNT(DISTINCT o.o_orderkey) AS total_orders,
        SUM(CASE WHEN l.l_returnflag = 'R' THEN 1 ELSE 0 END) AS total_returns
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
),
FinalReport AS (
    SELECT
        ts.nation_name,
        ts.s_name,
        ts.s_acctbal,
        stats.total_customers,
        stats.total_revenue,
        stats.avg_order_value,
        stats.total_orders,
        stats.total_returns
    FROM 
        TopSuppliers ts
    CROSS JOIN 
        AggregateStats stats
)
SELECT 
    nation_name,
    s_name,
    s_acctbal,
    total_customers,
    total_revenue,
    avg_order_value,
    total_orders,
    total_returns
FROM 
    FinalReport
ORDER BY 
    nation_name, s_acctbal DESC;
