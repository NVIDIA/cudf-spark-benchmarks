
WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        o.o_orderstatus,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS order_ranking
    FROM 
        orders AS o
),
SupplierStats AS (
    SELECT 
        s.s_nationkey,
        COUNT(DISTINCT ps.ps_partkey) AS total_parts,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM 
        supplier AS s
    JOIN 
        partsupp AS ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_nationkey
),
CustomerStats AS (
    SELECT 
        c.c_nationkey,
        AVG(c.c_acctbal) AS avg_account_balance,
        COUNT(DISTINCT o.o_orderkey) AS total_orders
    FROM 
        customer AS c
    LEFT JOIN 
        orders AS o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_nationkey
),
LineItemSummary AS (
    SELECT 
        l.l_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_lineitem_value,
        COUNT(*) AS total_items,
        MAX(l.l_shipdate) AS last_ship_date
    FROM 
        lineitem AS l
    GROUP BY 
        l.l_orderkey
)
SELECT 
    r.r_name AS region,
    ns.n_name AS nation,
    COUNT(DISTINCT co.o_orderkey) AS total_orders,
    ROUND(SUM(COALESCE(ls.total_lineitem_value, 0)), 2) AS total_value,
    ROUND(AVG(COALESCE(cs.avg_account_balance, 0)), 2) AS avg_customer_balance,
    SUM(s.total_parts) AS total_parts_provided,
    MAX(co.o_orderdate) AS latest_order_date
FROM 
    region AS r
JOIN 
    nation AS ns ON r.r_regionkey = ns.n_regionkey
LEFT JOIN 
    CustomerStats AS cs ON ns.n_nationkey = cs.c_nationkey
LEFT JOIN 
    SupplierStats AS s ON ns.n_nationkey = s.s_nationkey
LEFT JOIN 
    RankedOrders AS co ON co.o_orderdate BETWEEN '1997-01-01' AND '1997-12-31'
LEFT JOIN 
    LineItemSummary AS ls ON co.o_orderkey = ls.l_orderkey
GROUP BY 
    r.r_name, ns.n_name
HAVING 
    AVG(COALESCE(cs.avg_account_balance, 0)) > 500 AND COUNT(DISTINCT co.o_orderkey) > 10
ORDER BY 
    total_value DESC;
