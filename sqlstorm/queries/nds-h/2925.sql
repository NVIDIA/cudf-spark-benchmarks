
WITH SupplierStats AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost,
        COUNT(DISTINCT ps.ps_partkey) AS part_count
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
        COUNT(o.o_orderkey) AS order_count,
        SUM(o.o_totalprice) AS total_spent
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
),
OrderedStats AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        SUM(li.l_extendedprice * (1 - li.l_discount)) AS order_value
    FROM 
        orders o
    JOIN 
        lineitem li ON o.o_orderkey = li.l_orderkey
    WHERE 
        li.l_shipdate >= DATE '1997-01-01' AND li.l_shipdate < DATE '1997-10-01'
    GROUP BY 
        o.o_orderkey, o.o_orderdate
)
SELECT 
    r.r_name,
    COUNT(DISTINCT co.c_custkey) AS customer_count,
    SUM(ss.total_supply_cost) AS total_supplier_cost,
    AVG(os.order_value) AS average_order_value,
    SUM(CASE WHEN co.total_spent IS NOT NULL THEN co.total_spent ELSE 0 END) AS total_spent_by_customers
FROM 
    region r
LEFT JOIN 
    nation n ON n.n_regionkey = r.r_regionkey
LEFT JOIN 
    supplier s ON s.s_nationkey = n.n_nationkey
LEFT JOIN 
    SupplierStats ss ON s.s_suppkey = ss.s_suppkey
LEFT JOIN 
    CustomerOrders co ON s.s_nationkey = co.c_custkey
LEFT JOIN 
    OrderedStats os ON os.o_orderkey = co.order_count
WHERE 
    r.r_name IS NOT NULL
GROUP BY 
    r.r_name
HAVING 
    COUNT(DISTINCT co.c_custkey) > 5
ORDER BY 
    total_supplier_cost DESC
LIMIT 10;
