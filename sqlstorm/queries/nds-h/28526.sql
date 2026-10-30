
WITH RegionWiseSupplier AS (
    SELECT 
        r.r_name AS region_name,
        s.s_suppkey,
        s.s_name,
        s.s_address,
        s.s_phone,
        SUM(ps.ps_availqty) AS total_available_qty,
        SUM(ps.ps_supplycost) AS total_supply_cost
    FROM 
        region r
    JOIN 
        nation n ON r.r_regionkey = n.n_regionkey
    JOIN 
        supplier s ON n.n_nationkey = s.s_nationkey
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        r.r_name, s.s_suppkey, s.s_name, s.s_address, s.s_phone
),
HighValueCustomers AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        c.c_address,
        c.c_phone,
        c.c_acctbal,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_spent
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        c.c_custkey, c.c_name, c.c_address, c.c_phone, c.c_acctbal
    HAVING 
        SUM(l.l_extendedprice * (1 - l.l_discount)) > 10000
)
SELECT 
    rws.region_name,
    rws.s_name AS supplier_name,
    rws.total_available_qty,
    rws.total_supply_cost,
    hvc.c_name AS high_value_customer,
    hvc.total_spent
FROM 
    RegionWiseSupplier rws
JOIN 
    HighValueCustomers hvc ON rws.s_suppkey IN (
        SELECT ps.ps_suppkey
        FROM partsupp ps
        WHERE ps.ps_partkey IN (
            SELECT p.p_partkey
            FROM part p
            WHERE p.p_comment LIKE '%fragile%'
        )
    )
ORDER BY 
    rws.region_name, hvc.total_spent DESC;
