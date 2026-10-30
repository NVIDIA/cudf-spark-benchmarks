
WITH SupplierAggregates AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS TotalCost,
        COUNT(DISTINCT p.p_partkey) AS PartCount
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    GROUP BY 
        s.s_suppkey, s.s_name
),
CustomerOrderStats AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        COUNT(o.o_orderkey) AS OrderCount,
        SUM(o.o_totalprice) AS TotalSpent
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
),
OrderDetails AS (
    SELECT 
        o.o_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS Revenue,
        COUNT(l.l_linenumber) AS LineItemCount
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        o.o_orderkey
)
SELECT 
    ns.n_name AS Nation,
    s.s_name AS Supplier,
    sa.TotalCost AS SupplierTotalCost,
    COALESCE(cos.TotalSpent, 0) AS CustomerTotalSpent,
    ods.Revenue AS OrderRevenue, 
    ods.LineItemCount,
    RANK() OVER (PARTITION BY ns.n_name ORDER BY sa.TotalCost DESC) AS SupplierRank
FROM 
    nation ns
LEFT JOIN 
    supplier s ON ns.n_nationkey = s.s_nationkey
LEFT JOIN 
    SupplierAggregates sa ON s.s_suppkey = sa.s_suppkey
LEFT JOIN 
    CustomerOrderStats cos ON cos.OrderCount > 0 AND s.s_suppkey = (
        SELECT ps.ps_suppkey 
        FROM partsupp ps 
        WHERE ps.ps_partkey IN (
            SELECT p.p_partkey 
            FROM part p 
            WHERE p.p_brand = 'Brand#1'
        )
        LIMIT 1
    )
LEFT JOIN 
    OrderDetails ods ON ods.o_orderkey = (
        SELECT o.o_orderkey 
        FROM orders o 
        WHERE o.o_orderstatus = 'O' 
        LIMIT 1
    )
WHERE 
    (sa.PartCount IS NOT NULL OR sa.TotalCost IS NOT NULL)
ORDER BY 
    ns.n_name, SupplierRank;
