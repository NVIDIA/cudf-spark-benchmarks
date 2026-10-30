WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        ROW_NUMBER() OVER (PARTITION BY o.o_custkey ORDER BY o.o_orderdate DESC) AS rn
    FROM 
        orders o
    WHERE 
        o.o_orderstatus = 'O'
),
CustomerSupplierDetails AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        n.n_name AS nation_name,
        s.s_name AS supplier_name,
        SUM(ps.ps_supplycost) AS total_supply_cost
    FROM 
        customer c
    JOIN 
        nation n ON c.c_nationkey = n.n_nationkey
    LEFT JOIN 
        partsupp ps ON c.c_custkey = ps.ps_suppkey 
    LEFT JOIN 
        supplier s ON ps.ps_suppkey = s.s_suppkey
    GROUP BY 
        c.c_custkey, c.c_name, n.n_name, s.s_name
),
DiscountedLineItems AS (
    SELECT 
        l.l_orderkey,
        l.l_partkey,
        l.l_suppkey,
        l.l_quantity * (1 - l.l_discount) AS adjusted_price,
        ROW_NUMBER() OVER (PARTITION BY l.l_orderkey ORDER BY l.l_linenumber) AS line_rank
    FROM 
        lineitem l
    WHERE 
        l.l_discount < 0.05 
)
SELECT 
    r.o_orderkey,
    r.o_orderdate,
    r.o_totalprice,
    cs.c_name,
    cs.total_supply_cost,
    COALESCE(dl.adjusted_price, 0) AS total_discounted_price,
    CASE 
        WHEN r.o_totalprice > 1000 THEN 'High Value'
        ELSE 'Low Value' 
    END AS order_value_category
FROM 
    RankedOrders r
JOIN 
    CustomerSupplierDetails cs ON r.o_orderkey = cs.c_custkey 
LEFT JOIN 
    DiscountedLineItems dl ON r.o_orderkey = dl.l_orderkey AND dl.line_rank = 1 
WHERE 
    r.rn = 1 
ORDER BY 
    r.o_orderdate DESC, cs.total_supply_cost DESC;