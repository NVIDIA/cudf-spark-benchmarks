WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        ROW_NUMBER() OVER (PARTITION BY n.n_regionkey ORDER BY s.s_acctbal DESC) AS rn,
        n.n_name
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
),
RecentOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_custkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_value,
        o.o_orderdate
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderdate >= cast('1998-10-01' as date) - INTERVAL '1 year'
    GROUP BY 
        o.o_orderkey, o.o_custkey, o.o_orderdate
),
HighValueCustomers AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        SUM(RO.total_value) AS total_spent
    FROM 
        customer c
    JOIN 
        RecentOrders RO ON c.c_custkey = RO.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
    HAVING 
        SUM(RO.total_value) > 10000
),
SupplierInfo AS (
    SELECT 
        rw.s_suppkey,
        rw.s_name,
        COALESCE(rw.n_name, 'Unknown') AS region_name,
        hs.total_spent
    FROM 
        RankedSuppliers rw
    LEFT JOIN 
        HighValueCustomers hs ON rw.s_suppkey = hs.c_custkey
)

SELECT 
    si.s_name,
    si.region_name,
    si.total_spent,
    COUNT(DISTINCT ps.ps_partkey) AS total_parts_supplied
FROM 
    SupplierInfo si
LEFT JOIN 
    partsupp ps ON si.s_suppkey = ps.ps_suppkey
WHERE 
    si.total_spent IS NOT NULL
GROUP BY 
    si.s_name, si.region_name, si.total_spent
ORDER BY 
    total_parts_supplied DESC, total_spent DESC;