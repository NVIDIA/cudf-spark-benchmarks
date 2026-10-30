
WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        ROW_NUMBER() OVER (PARTITION BY p.p_partkey ORDER BY ps.ps_supplycost ASC) AS rn
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    WHERE 
        p.p_size IN (10, 20, 30) AND 
        s.s_acctbal > 5000
),
HighValueCustomers AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        c.c_acctbal
    FROM 
        customer c
    WHERE 
        c.c_acctbal > 10000
),
RecentOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_custkey,
        o.o_orderdate,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_order_value
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderdate >= CURRENT_DATE - INTERVAL '6 months'
    GROUP BY 
        o.o_orderkey, o.o_custkey, o.o_orderdate
),
AggregatedSupplierInfo AS (
    SELECT 
        rs.s_suppkey,
        rs.s_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_supply_value
    FROM 
        RankedSuppliers rs
    JOIN 
        lineitem l ON l.l_suppkey = rs.s_suppkey
    GROUP BY 
        rs.s_suppkey, rs.s_name
)
SELECT 
    rsi.s_suppkey,
    rsi.s_name,
    rsi.total_supply_value,
    hvc.c_custkey,
    hvc.c_name,
    hvc.c_acctbal,
    ro.total_order_value
FROM 
    AggregatedSupplierInfo rsi
JOIN 
    HighValueCustomers hvc ON rsi.total_supply_value > hvc.c_acctbal
JOIN 
    RecentOrders ro ON hvc.c_custkey = ro.o_custkey
WHERE 
    rsi.s_suppkey IN (SELECT s_suppkey FROM RankedSuppliers WHERE rn = 1)
ORDER BY 
    ro.total_order_value DESC, rsi.total_supply_value DESC;
