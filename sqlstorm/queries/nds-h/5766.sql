WITH RankedSuppliers AS (
    SELECT 
        s_name,
        s_acctbal,
        n_name AS nation_name,
        ROW_NUMBER() OVER (PARTITION BY n.n_nationkey ORDER BY s_acctbal DESC) AS rn
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
),
HighBalanceSuppliers AS (
    SELECT 
        s_name,
        s_acctbal,
        nation_name
    FROM 
        RankedSuppliers
    WHERE 
        rn <= 5
),
OrdersInfo AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderdate BETWEEN DATE '1997-01-01' AND DATE '1997-12-31'
    GROUP BY 
        o.o_orderkey, o.o_orderdate
),
TopOrders AS (
    SELECT 
        o.o_orderkey,
        o.total_revenue,
        RANK() OVER (ORDER BY o.total_revenue DESC) AS revenue_rank
    FROM 
        OrdersInfo o
)
SELECT 
    s.nation_name,
    s.s_name,
    o.o_orderkey,
    o.total_revenue
FROM 
    HighBalanceSuppliers s
JOIN 
    TopOrders o ON s.s_acctbal > (SELECT AVG(s_acctbal) FROM HighBalanceSuppliers)
WHERE 
    o.revenue_rank <= 10
ORDER BY 
    s.nation_name, o.total_revenue DESC;