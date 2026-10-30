
WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        c.c_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        RANK() OVER (PARTITION BY c.c_nationkey ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS revenue_rank
    FROM 
        orders o
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderdate >= DATE '1997-01-01'
        AND l.l_shipdate >= o.o_orderdate
    GROUP BY 
        o.o_orderkey, c.c_name, c.c_nationkey
),
SupplierParts AS (
    SELECT 
        ps.ps_partkey,
        s.s_name,
        p.p_name,
        ps.ps_availqty,
        ps.ps_supplycost
    FROM 
        partsupp ps
    JOIN 
        supplier s ON ps.ps_suppkey = s.s_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
),
HighValueSuppliers AS (
    SELECT 
        ps.ps_partkey,
        AVG(ps.ps_supplycost) AS avg_supply_cost
    FROM 
        SupplierParts ps
    GROUP BY 
        ps.ps_partkey
    HAVING 
        AVG(ps.ps_supplycost) < (SELECT AVG(ps_supplycost) FROM SupplierParts)
),
FinalResults AS (
    SELECT 
        ro.*, 
        hp.avg_supply_cost
    FROM 
        RankedOrders ro
    LEFT JOIN 
        HighValueSuppliers hp ON ro.o_orderkey = hp.ps_partkey
)
SELECT 
    fr.o_orderkey,
    fr.c_name,
    fr.total_revenue,
    COALESCE(fr.avg_supply_cost, 0) AS avg_supply_cost,
    CASE 
        WHEN fr.total_revenue > 10000 THEN 'High'
        WHEN fr.total_revenue BETWEEN 5000 AND 10000 THEN 'Medium'
        ELSE 'Low'
    END AS revenue_category
FROM 
    FinalResults fr
WHERE 
    fr.revenue_rank <= 10
ORDER BY 
    fr.total_revenue DESC;
