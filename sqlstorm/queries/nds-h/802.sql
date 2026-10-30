WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        o.o_orderpriority,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderpriority ORDER BY o.o_orderdate DESC) AS rn
    FROM 
        orders o
    WHERE 
        o.o_orderstatus = 'O' AND 
        o.o_orderdate >= '1997-01-01'
),
SupplierInfo AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_nationkey,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_value
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name, s.s_nationkey
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
FilteredLineItems AS (
    SELECT 
        l.l_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_amount
    FROM 
        lineitem l
    WHERE 
        l.l_shipdate BETWEEN '1997-01-01' AND '1997-12-31'
    GROUP BY 
        l.l_orderkey
)
SELECT 
    ro.o_orderkey,
    ro.o_orderdate,
    co.c_name AS customer_name,
    ro.o_totalprice,
    si.s_name AS supplier_name,
    fl.total_amount AS line_item_total,
    CASE 
        WHEN ro.o_totalprice > fl.total_amount THEN 'Under Budget'
        ELSE 'Over Budget'
    END AS budget_status
FROM 
    RankedOrders ro
JOIN 
    CustomerOrders co ON ro.o_orderkey = co.c_custkey
LEFT JOIN 
    FilteredLineItems fl ON ro.o_orderkey = fl.l_orderkey
LEFT JOIN 
    SupplierInfo si ON si.total_supply_value = 
        (SELECT MAX(total_supply_value) FROM SupplierInfo)
WHERE 
    co.order_count > 5 
ORDER BY 
    ro.o_orderdate DESC, ro.o_totalprice DESC;