
WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        o.o_orderstatus,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS order_rank
    FROM 
        orders o
    WHERE 
        o.o_orderdate >= CURRENT_TIMESTAMP - INTERVAL '6 MONTH'
),
OrderLineDetails AS (
    SELECT 
        l.l_orderkey,
        l.l_quantity,
        l.l_extendedprice,
        l.l_discount,
        l.l_tax,
        l.l_returnflag,
        l.l_shipmode,
        l.l_commitdate,
        l.l_shipdate,
        l.l_receiptdate,
        COALESCE(NULLIF(s.s_name, ''), 'No Supplier') AS supplier_name,
        COALESCE(NULLIF(p.p_name, ''), 'Unknown Part') AS part_name
    FROM 
        lineitem l
    LEFT JOIN 
        supplier s ON l.l_suppkey = s.s_suppkey
    JOIN 
        partsupp ps ON l.l_partkey = ps.ps_partkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    WHERE 
        l.l_shipdate IS NOT NULL
        AND l.l_discount BETWEEN 0.05 AND 0.20
),
HighValueOrders AS (
    SELECT 
        o.o_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS order_value
    FROM 
        RankedOrders o
    JOIN 
        OrderLineDetails l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        o.o_orderkey
    HAVING 
        SUM(l.l_extendedprice * (1 - l.l_discount)) > 1000
),
FinalReport AS (
    SELECT 
        r.r_name AS region,
        n.n_name AS nation,
        c.c_name AS customer,
        o.o_orderkey,
        o.order_value,
        ROW_NUMBER() OVER (PARTITION BY n.n_nationkey ORDER BY o.order_value DESC) AS report_rank
    FROM 
        HighValueOrders o
    JOIN 
        customer c ON o.o_orderkey = c.c_custkey
    JOIN 
        nation n ON c.c_nationkey = n.n_nationkey
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
)
SELECT 
    region,
    nation,
    customer,
    o_orderkey,
    order_value,
    report_rank
FROM 
    FinalReport
WHERE 
    report_rank <= 5
UNION ALL
SELECT 
    'TOTAL' AS region,
    'ALL' AS nation,
    'Aggregate' AS customer,
    NULL AS o_orderkey,
    SUM(order_value) AS order_value,
    NULL AS report_rank
FROM 
    FinalReport
GROUP BY 
    GROUPING SETS (region, nation, customer);
