WITH TotalCost AS (
    SELECT 
        ps.ps_partkey,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM 
        partsupp ps
    GROUP BY 
        ps.ps_partkey
),
SupplierDetails AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        n.n_name AS nation_name,
        r.r_name AS region_name,
        s.s_acctbal
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
),
CustomerOrders AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    WHERE 
        o.o_orderdate BETWEEN '1997-01-01' AND '1997-12-31'
)
SELECT 
    d.s_suppkey,
    d.s_name,
    d.nation_name,
    d.region_name,
    tc.total_supply_cost,
    COUNT(co.o_orderkey) AS order_count,
    SUM(co.o_totalprice) AS total_customer_spent
FROM 
    SupplierDetails d
LEFT JOIN 
    TotalCost tc ON d.s_suppkey = tc.ps_partkey
LEFT JOIN 
    lineitem l ON d.s_suppkey = l.l_suppkey
LEFT JOIN 
    CustomerOrders co ON l.l_orderkey = co.o_orderkey
GROUP BY 
    d.s_suppkey, d.s_name, d.nation_name, d.region_name, tc.total_supply_cost
ORDER BY 
    total_customer_spent DESC, d.s_suppkey;