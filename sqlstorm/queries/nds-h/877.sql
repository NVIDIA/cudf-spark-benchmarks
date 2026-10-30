
WITH SupplierCosts AS (
    SELECT 
        ps.ps_suppkey,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS TotalCost,
        COUNT(DISTINCT ps.ps_partkey) AS NumParts
    FROM 
        partsupp ps
    GROUP BY 
        ps.ps_suppkey
),
OrderSummary AS (
    SELECT 
        o.o_custkey,
        SUM(o.o_totalprice) AS TotalOrders,
        AVG(o.o_totalprice) AS AvgOrderValue,
        COUNT(o.o_orderkey) AS OrderCount
    FROM 
        orders o
    WHERE 
        o.o_orderstatus = 'O' 
        AND o.o_orderdate > '1997-01-01'
    GROUP BY 
        o.o_custkey
),
LineitemAnalysis AS (
    SELECT 
        l.l_orderkey,
        l.l_partkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS AdjustedRevenue,
        AVG(l.l_quantity) AS AvgQuantity
    FROM 
        lineitem l
    WHERE 
        l.l_shipdate BETWEEN '1997-01-01' AND '1997-12-31'
    GROUP BY 
        l.l_orderkey, l.l_partkey
)
SELECT 
    n.n_name,
    r.r_name,
    sc.TotalCost,
    os.TotalOrders,
    la.AdjustedRevenue,
    la.AvgQuantity
FROM 
    region r
JOIN 
    nation n ON r.r_regionkey = n.n_regionkey
LEFT JOIN 
    SupplierCosts sc ON n.n_nationkey = sc.ps_suppkey
LEFT JOIN 
    OrderSummary os ON n.n_nationkey = os.o_custkey
LEFT JOIN 
    LineitemAnalysis la ON la.l_orderkey IN (SELECT o.o_orderkey FROM orders o WHERE o.o_custkey = os.o_custkey)
WHERE 
    (sc.TotalCost IS NOT NULL OR os.TotalOrders IS NOT NULL)
    AND r.r_name LIKE '%North%'
ORDER BY 
    n.n_name, r.r_name;
