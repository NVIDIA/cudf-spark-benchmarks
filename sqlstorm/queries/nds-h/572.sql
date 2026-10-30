
WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        o.o_orderstatus,
        ROW_NUMBER() OVER(PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS order_rank
    FROM 
        orders o
    WHERE 
        o.o_orderdate >= CURRENT_DATE - INTERVAL '2 years'
), 
SupplierDetails AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_nationkey,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost,
        COUNT(DISTINCT p.p_partkey) AS part_count
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    GROUP BY 
        s.s_suppkey, s.s_name, s.s_nationkey
), 
CustomerSummary AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        SUM(o.o_totalprice) AS total_spent,
        COUNT(o.o_orderkey) AS order_count
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
), 
TotalByRegion AS (
    SELECT 
        n.n_regionkey,
        r.r_name,
        SUM(o.o_totalprice) AS total_value,
        COUNT(o.o_orderkey) AS total_orders
    FROM 
        nation n
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
    LEFT JOIN 
        orders o ON n.n_nationkey = o.o_custkey
    GROUP BY 
        n.n_regionkey, r.r_name
)
SELECT 
    COALESCE(c.c_name, 'Unknown Customer') AS customer_name,
    COALESCE(o.o_orderkey, -1) AS order_id,
    so.s_name AS supplier_name,
    so.total_supply_cost AS supplier_total_cost,
    ta.total_value AS region_total
FROM 
    CustomerSummary c
FULL OUTER JOIN 
    RankedOrders o ON c.c_custkey = o.o_orderkey
LEFT JOIN 
    SupplierDetails so ON so.s_nationkey = c.c_custkey
LEFT JOIN 
    TotalByRegion ta ON ta.total_orders = (SELECT MAX(total_orders) FROM TotalByRegion)
WHERE 
    (c.total_spent IS NOT NULL OR o.o_orderstatus = 'O')
ORDER BY 
    c.total_spent DESC, o.o_orderdate;
