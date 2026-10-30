WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        RANK() OVER (PARTITION BY p.p_type ORDER BY SUM(ps.ps_supplycost) DESC) as SupplierRank,
        SUM(ps.ps_supplycost) AS TotalSupplyCost
    FROM 
        supplier s 
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    GROUP BY 
        s.s_suppkey, s.s_name, p.p_type
),
TopSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        s.s_comment,
        rs.TotalSupplyCost
    FROM 
        supplier s
    JOIN 
        RankedSuppliers rs ON s.s_suppkey = rs.s_suppkey
    WHERE 
        rs.SupplierRank <= 2
),
CustomerOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_custkey,
        c.c_mktsegment,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS TotalOrderValue
    FROM 
        orders o 
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        o.o_orderkey, o.o_custkey, c.c_mktsegment
),
OrderSummary AS (
    SELECT 
        co.o_orderkey,
        co.c_mktsegment,
        SUM(co.TotalOrderValue) AS TotalValue,
        COUNT(co.o_orderkey) as OrderCount
    FROM 
        CustomerOrders co
    GROUP BY 
        co.o_orderkey, co.c_mktsegment
)
SELECT 
    ts.s_name,
    ts.TotalSupplyCost,
    os.c_mktsegment,
    os.TotalValue,
    os.OrderCount,
    CASE 
        WHEN os.TotalValue IS NULL THEN 'No Orders'
        ELSE 'Has Orders'
    END AS OrderStatus,
    RANK() OVER (ORDER BY ts.TotalSupplyCost DESC) AS GlobalSupplierRank,
    COALESCE(NULLIF(ts.s_comment, ''), 'No Comment Provided') AS SupplierComment
FROM 
    TopSuppliers ts
LEFT JOIN 
    OrderSummary os ON ts.s_suppkey = os.o_orderkey 
WHERE 
    ts.TotalSupplyCost > (SELECT AVG(TotalSupplyCost) FROM TopSuppliers)
    OR ts.s_acctbal IS NULL
ORDER BY 
    ts.TotalSupplyCost DESC, os.OrderCount ASC;
