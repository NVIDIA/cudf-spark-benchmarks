
WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS order_rank
    FROM 
        orders o
    WHERE 
        o.o_orderdate >= DATE '1997-01-01' AND o.o_orderdate < DATE '1997-12-31'
),
SupplierStats AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        COUNT(DISTINCT ps.ps_partkey) AS total_parts_supplied,
        SUM(ps.ps_supplycost) AS total_supply_cost,
        AVG(s.s_acctbal) AS avg_account_balance
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
),
CustomerSegment AS (
    SELECT 
        c.c_mktsegment,
        COUNT(c.c_custkey) AS num_customers,
        SUM(o.o_totalprice) AS total_orders_value
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_mktsegment
),
OrderDetails AS (
    SELECT 
        lo.l_orderkey,
        p.p_name,
        lo.l_extendedprice * (1 - lo.l_discount) AS net_price
    FROM 
        lineitem lo
    JOIN 
        part p ON lo.l_partkey = p.p_partkey
    WHERE 
        lo.l_shipdate BETWEEN DATE '1997-06-01' AND DATE '1997-06-30'
)
SELECT 
    rs.o_orderkey AS order_key,
    rs.o_totalprice AS order_price,
    ss.s_name AS supplier_name,
    cs.c_mktsegment AS market_segment,
    ds.p_name AS part_name,
    SUM(ds.net_price) AS total_net_price,
    COUNT(DISTINCT rs.o_orderkey) AS unique_order_count,
    COALESCE(AVG(ss.total_supply_cost), 0) AS avg_supply_cost
FROM 
    RankedOrders rs
LEFT JOIN 
    SupplierStats ss ON ss.total_parts_supplied > 5
LEFT JOIN 
    CustomerSegment cs ON cs.num_customers > 100
LEFT JOIN 
    OrderDetails ds ON rs.o_orderkey = ds.l_orderkey
WHERE 
    rs.order_rank <= 10
GROUP BY 
    rs.o_orderkey, rs.o_totalprice, ss.s_name, cs.c_mktsegment, ds.p_name
ORDER BY 
    total_net_price DESC
LIMIT 50;
