WITH  RankedOrders AS (
    SELECT
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        ROW_NUMBER() OVER (PARTITION BY c.c_nationkey ORDER BY o.o_orderdate DESC) AS order_rank
    FROM
        orders o
    JOIN
        customer c ON o.o_custkey = c.c_custkey
    WHERE
        o.o_orderstatus = 'F' AND
        o.o_orderdate >= (cast('1998-10-01' as date) - INTERVAL '1 year')
), 
SupplierPrice AS (
    SELECT 
        ps.ps_partkey, 
        s.s_suppkey, 
        SUM(ps.ps_supplycost) AS total_supply_cost
    FROM 
        partsupp ps
    JOIN 
        supplier s ON ps.ps_suppkey = s.s_suppkey 
    GROUP BY 
        ps.ps_partkey, 
        s.s_suppkey
), 
PartDetails AS (
    SELECT 
        p.p_partkey, 
        p.p_name, 
        p.p_retailprice, 
        COALESCE(SUM(ps.ps_availqty), 0) AS total_available_quantity,
        COALESCE(MAX(sp.total_supply_cost), 0) AS max_supply_cost
    FROM 
        part p
    LEFT JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    LEFT JOIN 
        SupplierPrice sp ON p.p_partkey = sp.ps_partkey
    GROUP BY 
        p.p_partkey, 
        p.p_name, 
        p.p_retailprice
)
SELECT 
    r.r_name, 
    COUNT(DISTINCT ro.o_orderkey) AS num_orders,
    AVG(pd.p_retailprice) AS avg_retail_price,
    MAX(pd.max_supply_cost) AS max_supply_cost,
    (SELECT COUNT(*)
     FROM lineitem l 
     WHERE l.l_shipdate > (cast('1998-10-01' as date) - INTERVAL '30 day')
       AND l.l_returnflag = 'R') AS recent_returns
FROM 
    region r
JOIN 
    nation n ON r.r_regionkey = n.n_regionkey
JOIN 
    customer c ON n.n_nationkey = c.c_nationkey
JOIN 
    RankedOrders ro ON c.c_custkey = ro.o_orderkey
JOIN 
    PartDetails pd ON pd.p_partkey IN (SELECT DISTINCT l.l_partkey 
                                         FROM lineitem l 
                                         WHERE l.l_orderkey = ro.o_orderkey)
WHERE 
    r.r_name LIKE 'A%' 
    AND EXISTS (SELECT 1 FROM supplier s WHERE s.s_nationkey = n.n_nationkey AND s.s_acctbal > 5000)
GROUP BY 
    r.r_name
ORDER BY 
    num_orders DESC, 
    r.r_name ASC
LIMIT 10;