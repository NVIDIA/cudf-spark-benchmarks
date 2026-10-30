WITH RankedCustomers AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        c.c_acctbal,
        ROW_NUMBER() OVER (PARTITION BY c.c_mktsegment ORDER BY c.c_acctbal DESC) AS rank
    FROM 
        customer c
    WHERE 
        c.c_acctbal > (SELECT AVG(c2.c_acctbal) FROM customer c2)
),
SupplierInfo AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_value
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
),
OrderStats AS (
    SELECT 
        o.o_orderkey,
        o.o_orderstatus,
        COUNT(l.l_orderkey) AS total_line_items,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM 
        orders o
    LEFT JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderdate BETWEEN '1997-01-01' AND '1997-12-31'
    GROUP BY 
        o.o_orderkey, o.o_orderstatus
)
SELECT 
    r.c_name AS customer_name,
    r.c_acctbal AS customer_balance,
    si.s_name AS supplier_name,
    si.total_supply_value,
    os.o_orderkey,
    os.total_line_items,
    os.total_revenue,
    CASE 
        WHEN os.o_orderstatus = 'F' THEN 'Finalized'
        ELSE 'Pending'
    END AS order_status,
    CASE 
        WHEN r.rank <= 10 THEN 'Top Customer'
        ELSE 'Regular Customer'
    END AS customer_category
FROM 
    RankedCustomers r
LEFT JOIN 
    OrderStats os ON r.c_custkey = os.o_orderkey
LEFT JOIN 
    SupplierInfo si ON os.total_line_items > 0
ORDER BY 
    r.c_acctbal DESC, si.total_supply_value DESC, os.total_revenue DESC
LIMIT 100;