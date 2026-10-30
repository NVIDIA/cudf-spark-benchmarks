
WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderkey ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS order_rank
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        o.o_orderkey, o.o_orderdate
), SupplierParts AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
), NationRevenue AS (
    SELECT 
        n.n_name,
        SUM(r.total_revenue) AS total_revenue_by_nation
    FROM 
        nation n
    JOIN 
        supplier s ON n.n_nationkey = s.s_nationkey
    JOIN 
        RankedOrders r ON r.o_orderkey IN (
            SELECT DISTINCT o.o_orderkey 
            FROM orders o 
            JOIN lineitem l ON o.o_orderkey = l.l_orderkey
            WHERE l.l_shipdate >= DATE '1997-01-01'
        )
    GROUP BY 
        n.n_name
)
SELECT 
    COALESCE(n.n_name, 'Unknown') AS nation_name,
    COALESCE(nr.total_revenue_by_nation, 0) AS total_revenue,
    sp.s_name AS supplier_name,
    sp.total_supply_cost
FROM 
    NationRevenue nr
FULL OUTER JOIN SupplierParts sp ON nr.total_revenue_by_nation > 0
LEFT JOIN nation n ON n.n_name = nr.n_name
WHERE 
    (nr.total_revenue_by_nation IS NOT NULL OR sp.total_supply_cost IS NOT NULL)
ORDER BY 
    COALESCE(nr.total_revenue_by_nation, 0) DESC, sp.s_name ASC;
