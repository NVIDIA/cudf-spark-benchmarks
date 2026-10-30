
WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS TotalSupplyCost,
        RANK() OVER (PARTITION BY p.p_type ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) AS SupplierRank
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    GROUP BY 
        s.s_suppkey, s.s_name, p.p_type
),
DistinctCustomerCount AS (
    SELECT 
        o.o_orderkey,
        COUNT(DISTINCT c.c_custkey) AS DistinctCustomerCount
    FROM 
        orders o
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
    GROUP BY 
        o.o_orderkey
),
FinalBenchmark AS (
    SELECT 
        r.r_name,
        SUM(DISTINCT DistinctCustomerCount.DistinctCustomerCount) AS TotalCustomers,
        COUNT(DISTINCT RankedSuppliers.s_name) AS UniqueSuppliers
    FROM 
        region r
    JOIN 
        nation n ON r.r_regionkey = n.n_regionkey
    JOIN 
        supplier s ON n.n_nationkey = s.s_nationkey
    LEFT JOIN 
        RankedSuppliers ON s.s_suppkey = RankedSuppliers.s_suppkey
    LEFT JOIN 
        DistinctCustomerCount ON RankedSuppliers.s_suppkey = DistinctCustomerCount.o_orderkey
    GROUP BY 
        r.r_name
)
SELECT 
    r_name, 
    TotalCustomers, 
    UniqueSuppliers 
FROM 
    FinalBenchmark 
WHERE 
    UniqueSuppliers > 5 
ORDER BY 
    TotalCustomers DESC;
