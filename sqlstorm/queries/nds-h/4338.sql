WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderkey ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS rank
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderdate >= DATE '1997-01-01' AND o.o_orderdate < DATE '1998-01-01'
    GROUP BY 
        o.o_orderkey
),
HighValueOrders AS (
    SELECT 
        o_orderkey,
        total_revenue
    FROM 
        RankedOrders
    WHERE 
        rank <= 10
),
SupplierPartInfo AS (
    SELECT 
        s.s_suppkey,
        p.p_partkey,
        p.p_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    GROUP BY 
        s.s_suppkey, p.p_partkey, p.p_name
)
SELECT 
    h.o_orderkey,
    COALESCE(s.p_name, 'Unknown Part') AS part_name,
    s.total_supply_cost,
    h.total_revenue,
    CASE 
        WHEN h.total_revenue > 10000 THEN 'High Revenue'
        WHEN h.total_revenue BETWEEN 5000 AND 10000 THEN 'Medium Revenue'
        ELSE 'Low Revenue'
    END AS revenue_category,
    RANK() OVER (ORDER BY h.total_revenue DESC) AS revenue_rank
FROM 
    HighValueOrders h
LEFT JOIN 
    SupplierPartInfo s ON h.o_orderkey = s.p_partkey
ORDER BY 
    h.total_revenue DESC;