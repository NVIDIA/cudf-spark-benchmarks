WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderstatus,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
        RANK() OVER (PARTITION BY o.o_orderstatus ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS sales_rank
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        o.o_orderkey, o.o_orderstatus
), SupplierAgg AS (
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
), NationCustomer AS (
    SELECT 
        n.n_nationkey,
        n.n_name,
        COUNT(DISTINCT c.c_custkey) AS customer_count
    FROM 
        customer c
    JOIN 
        nation n ON c.c_nationkey = n.n_nationkey
    GROUP BY 
        n.n_nationkey, n.n_name
)
SELECT 
    r.r_name,
    ra.sales_rank,
    ra.total_sales,
    sa.s_name,
    sa.total_supply_cost,
    nc.customer_count
FROM 
    RankedOrders ra
JOIN 
    SupplierAgg sa ON ra.o_orderkey % 100 = sa.s_suppkey % 100  
JOIN 
    region r ON ra.o_orderstatus = 'F'  
JOIN 
    NationCustomer nc ON sa.s_suppkey % 5 = nc.n_nationkey % 5  
WHERE 
    ra.sales_rank <= 10
ORDER BY 
    r.r_name, ra.total_sales DESC;