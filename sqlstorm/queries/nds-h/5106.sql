WITH SupplierTotal AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
), 
CustomerOrders AS (
    SELECT 
        c.c_custkey, 
        c.c_name, 
        SUM(o.o_totalprice) AS total_order_value
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
), 
NationRegionSupplier AS (
    SELECT 
        n.n_nationkey, 
        n.n_name, 
        r.r_regionkey, 
        r.r_name, 
        SUM(st.total_supply_cost) AS region_total_supply_cost
    FROM 
        nation n
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
    JOIN 
        SupplierTotal st ON st.s_suppkey IN (SELECT ps.ps_suppkey FROM partsupp ps 
                                              JOIN part p ON ps.ps_partkey = p.p_partkey 
                                              WHERE p.p_type = 'PROMO')
    GROUP BY 
        n.n_nationkey, n.n_name, r.r_regionkey, r.r_name
)
SELECT 
    nr.r_name, 
    nr.n_name, 
    COUNT(DISTINCT co.c_custkey) AS unique_customers, 
    SUM(co.total_order_value) AS total_sales_value, 
    SUM(nr.region_total_supply_cost) AS total_supply_cost
FROM 
    CustomerOrders co
JOIN 
    NationRegionSupplier nr ON co.c_custkey IN (SELECT c.c_custkey FROM customer c WHERE c.c_nationkey = nr.n_nationkey)
GROUP BY 
    nr.r_name, nr.n_name
ORDER BY 
    total_sales_value DESC, total_supply_cost DESC
LIMIT 10;
