WITH RankedParts AS (
    SELECT 
        p.p_partkey, 
        p.p_name, 
        p.p_brand, 
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost,
        RANK() OVER (PARTITION BY p.p_brand ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) AS rk
    FROM 
        part p
    JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY 
        p.p_partkey, p.p_name, p.p_brand
),
CustomerOrderTotals AS (
    SELECT 
        c.c_custkey, 
        SUM(o.o_totalprice) AS customer_total
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey
),
HighValueCustomers AS (
    SELECT 
        c.c_custkey, 
        c.c_name, 
        ct.customer_total
    FROM 
        customer c
    JOIN 
        CustomerOrderTotals ct ON c.c_custkey = ct.c_custkey
    WHERE 
        ct.customer_total > 10000
)
SELECT 
    r.r_name AS region_name, 
    p.p_brand AS part_brand, 
    SUM(lp.l_extendedprice) AS total_sales, 
    COUNT(DISTINCT hvc.c_custkey) AS high_value_customers
FROM 
    lineitem lp
JOIN 
    orders o ON lp.l_orderkey = o.o_orderkey
JOIN 
    customer c ON o.o_custkey = c.c_custkey
JOIN 
    nation n ON c.c_nationkey = n.n_nationkey
JOIN 
    region r ON n.n_regionkey = r.r_regionkey
JOIN 
    RankedParts p ON lp.l_partkey = p.p_partkey
JOIN 
    HighValueCustomers hvc ON c.c_custkey = hvc.c_custkey
WHERE 
    lp.l_shipdate BETWEEN '1997-01-01' AND '1997-12-31'
GROUP BY 
    r.r_name, p.p_brand
ORDER BY 
    region_name, total_sales DESC;