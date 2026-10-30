
WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS order_rank
    FROM 
        orders o
    WHERE 
        o.o_orderdate BETWEEN '1997-01-01' AND '1997-12-31'
),
SupplierInfo AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        ROW_NUMBER() OVER (PARTITION BY s.s_nationkey ORDER BY s.s_acctbal DESC) AS bal_rank
    FROM 
        supplier s
    WHERE 
        s.s_acctbal IS NOT NULL AND s.s_acctbal > 0
),
CustomerInfo AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        n.n_name AS nation_name,
        c.c_acctbal,
        COUNT(DISTINCT o.o_orderkey) AS order_count
    FROM 
        customer c
    JOIN 
        nation n ON c.c_nationkey = n.n_nationkey
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name, n.n_name, c.c_acctbal
    HAVING 
        SUM(CASE WHEN o.o_orderstatus = 'F' THEN 1 ELSE 0 END) > 2
),
PartDetails AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_type,
        SUM(ps.ps_availqty) AS total_available,
        AVG(ps.ps_supplycost) AS average_supply_cost
    FROM 
        part p
    JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY 
        p.p_partkey, p.p_name, p.p_type
    HAVING 
        SUM(CASE WHEN p.p_size > 10 THEN ps.ps_availqty ELSE 0 END) > 100
)
SELECT 
    ci.c_name AS customer_name,
    ci.nation_name,
    COUNT(DISTINCT lo.o_orderkey) AS total_orders,
    COALESCE(SUM(li.l_extendedprice * (1 - li.l_discount)), 0) AS total_revenue,
    pd.p_name AS popular_part,
    pd.total_available,
    sd.s_name AS top_supplier
FROM 
    CustomerInfo ci
LEFT JOIN 
    orders lo ON ci.c_custkey = lo.o_custkey
LEFT JOIN 
    lineitem li ON lo.o_orderkey = li.l_orderkey
JOIN 
    PartDetails pd ON li.l_partkey = pd.p_partkey
LEFT JOIN 
    SupplierInfo sd ON li.l_suppkey = sd.s_suppkey AND sd.bal_rank = 1
WHERE 
    ci.order_count > 5
GROUP BY 
    ci.c_name, ci.nation_name, pd.p_name, pd.total_available, sd.s_name
ORDER BY 
    total_revenue DESC, ci.c_name
LIMIT 10;
