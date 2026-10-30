WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        RANK() OVER (PARTITION BY c.c_nationkey ORDER BY o.o_totalprice DESC) AS order_rank
    FROM 
        orders o
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
    WHERE 
        o.o_orderdate >= '1996-01-01' AND o.o_orderdate <= '1996-12-31'
),
TopSuppliers AS (
    SELECT 
        ps.ps_suppkey,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM 
        partsupp ps
    GROUP BY 
        ps.ps_suppkey
    HAVING 
        SUM(ps.ps_supplycost * ps.ps_availqty) > 10000
),
ProductsWithComments AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_retailprice,
        COALESCE(NULLIF(p.p_comment, ''), 'No comments') AS adjusted_comment
    FROM 
        part p
    WHERE 
        p.p_retailprice > 50.00
),
NationStatistics AS (
    SELECT 
        n.n_name,
        COUNT(DISTINCT c.c_custkey) AS customer_count,
        AVG(c.c_acctbal) AS average_acctbal,
        SUM(l.l_quantity) AS total_quantity
    FROM 
        nation n
    LEFT JOIN 
        customer c ON n.n_nationkey = c.c_nationkey
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    LEFT JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        n.n_name
)
SELECT 
    ns.n_name,
    ns.customer_count,
    ns.average_acctbal,
    ns.total_quantity,
    COUNT(DISTINCT ro.o_orderkey) AS total_orders,
    SUM(CASE WHEN ro.order_rank <= 5 THEN ro.o_totalprice ELSE 0 END) AS top_order_total
FROM 
    NationStatistics ns
LEFT JOIN 
    RankedOrders ro ON ns.customer_count > 0
GROUP BY 
    ns.n_name, ns.customer_count, ns.average_acctbal, ns.total_quantity
ORDER BY 
    ns.average_acctbal DESC, ns.customer_count DESC;