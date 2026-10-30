
WITH SupplierDetail AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS TotalCost,
        ROW_NUMBER() OVER (PARTITION BY s.s_nationkey ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) AS RankInNation
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name, s.s_nationkey
),
TopSuppliers AS (
    SELECT 
        d.s_suppkey,
        d.s_name,
        d.TotalCost
    FROM 
        SupplierDetail d
    WHERE 
        d.RankInNation <= 3
),
OrderSummary AS (
    SELECT 
        o.o_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS TotalRevenue
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderstatus = 'F'
    GROUP BY 
        o.o_orderkey
)
SELECT 
    n.n_name AS NationName,
    COALESCE(TS.s_name, 'No Supplier') AS SupplierName,
    COALESCE(OS.TotalRevenue, 0) AS TotalRevenue,
    CASE 
        WHEN OS.TotalRevenue IS NULL THEN 'No Orders'
        ELSE 'Orders Present'
    END AS OrderStatus
FROM 
    nation n
LEFT JOIN 
    TopSuppliers TS ON n.n_nationkey = TS.s_suppkey
LEFT JOIN 
    OrderSummary OS ON TS.s_suppkey = (
        SELECT 
            l.l_suppkey 
        FROM 
            lineitem l 
        JOIN 
            orders o ON l.l_orderkey = o.o_orderkey 
        WHERE 
            o.o_orderkey IN (SELECT o_orderkey FROM orders) 
        LIMIT 1
    )
WHERE 
    n.n_regionkey = (
        SELECT 
            r.r_regionkey 
        FROM 
            region r 
        WHERE 
            r.r_name = 'ASIA'
            AND r.r_comment IS NOT NULL
    )
ORDER BY 
    NationName,
    TotalRevenue DESC;
