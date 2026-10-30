
WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_custkey,
        o.o_orderdate,
        o.o_orderstatus,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        ROW_NUMBER() OVER (PARTITION BY o.o_custkey ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS rn
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderdate >= DATE '1997-01-01'
    GROUP BY 
        o.o_orderkey, o.o_custkey, o.o_orderdate, o.o_orderstatus
),
TopCustomers AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        c.c_acctbal,
        r.r_name,
        o.total_revenue
    FROM 
        customer c
    LEFT JOIN 
        nation n ON c.c_nationkey = n.n_nationkey
    LEFT JOIN 
        region r ON n.n_regionkey = r.r_regionkey
    JOIN 
        RankedOrders o ON c.c_custkey = o.o_custkey
    WHERE 
        o.rn = 1
),
SupplierDetails AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        COUNT(DISTINCT ps.ps_partkey) AS part_count,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS supply_value
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
),
PerformanceBenchmark AS (
    SELECT 
        tc.c_name,
        tc.c_acctbal,
        COALESCE(sd.part_count, 0) AS supplier_part_count,
        COALESCE(sd.supply_value, 0) AS supplier_supply_value,
        CASE 
            WHEN tc.total_revenue > 10000 THEN 'High Value'
            WHEN tc.total_revenue BETWEEN 5000 AND 10000 THEN 'Medium Value'
            ELSE 'Low Value'
        END AS revenue_category
    FROM 
        TopCustomers tc
    LEFT JOIN 
        SupplierDetails sd ON tc.c_custkey = sd.s_suppkey
)
SELECT 
    pb.c_name,
    pb.c_acctbal,
    pb.supplier_part_count,
    pb.supplier_supply_value,
    pb.revenue_category
FROM 
    PerformanceBenchmark pb
WHERE 
    pb.c_acctbal IS NOT NULL
ORDER BY 
    pb.supplier_supply_value DESC, pb.c_acctbal DESC;
