WITH SupplierSummary AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name, s.s_acctbal
),
CustomerOrders AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        COUNT(o.o_orderkey) AS order_count,
        SUM(o.o_totalprice) AS total_spent
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
),
RegionDetails AS (
    SELECT 
        r.r_regionkey,
        r.r_name,
        COUNT(n.n_nationkey) AS nation_count
    FROM 
        region r
    JOIN 
        nation n ON r.r_regionkey = n.n_regionkey
    GROUP BY 
        r.r_regionkey, r.r_name
)
SELECT 
    ss.s_name AS supplier_name,
    ss.total_supply_cost,
    co.c_name AS customer_name,
    co.order_count,
    co.total_spent,
    rd.r_name AS region_name,
    rd.nation_count
FROM 
    SupplierSummary ss
JOIN 
    CustomerOrders co ON ss.s_suppkey = co.c_custkey
JOIN 
    nation n ON co.c_custkey = n.n_nationkey
JOIN 
    RegionDetails rd ON n.n_regionkey = rd.r_regionkey
WHERE 
    ss.total_supply_cost > 10000
ORDER BY 
    ss.total_supply_cost DESC, co.total_spent DESC;
