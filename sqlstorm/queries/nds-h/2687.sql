WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_orderdate DESC) AS order_rank
    FROM 
        orders o
    WHERE 
        o.o_orderdate >= DATE '1997-01-01' AND 
        o.o_orderdate < DATE '1997-12-31'
), SupplierDetails AS (
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
), CustomerTotalSpend AS (
    SELECT 
        c.c_custkey,
        SUM(o.o_totalprice) AS total_spent
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey
), OrderLineSummary AS (
    SELECT 
        l.l_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_line_value,
        COUNT(l.l_linenumber) AS line_count
    FROM 
        lineitem l
    GROUP BY 
        l.l_orderkey
)
SELECT 
    c.c_name,
    COUNT(DISTINCT o.o_orderkey) AS total_orders,
    COALESCE(SUM(ots.total_line_value), 0) AS total_line_value,
    COALESCE(cs.total_spent, 0) AS customer_spent,
    CASE 
        WHEN cs.total_spent IS NULL THEN 'No Orders'
        WHEN cs.total_spent > 1000 THEN 'High Value'
        ELSE 'Low Value'
    END AS customer_value_segment
FROM 
    customer c
LEFT JOIN 
    orders o ON c.c_custkey = o.o_custkey
LEFT JOIN 
    OrderLineSummary ots ON o.o_orderkey = ots.l_orderkey
LEFT JOIN 
    CustomerTotalSpend cs ON c.c_custkey = cs.c_custkey
WHERE 
    c.c_acctbal IS NOT NULL AND 
    c.c_acctbal > 100
GROUP BY 
    c.c_name, cs.total_spent
HAVING 
    COUNT(DISTINCT o.o_orderkey) > 0
ORDER BY 
    total_orders DESC, total_line_value DESC;