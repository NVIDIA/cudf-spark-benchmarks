WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        o.o_orderstatus,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_orderdate DESC) AS rn
    FROM 
        orders o
    WHERE 
        o.o_orderdate >= DATE '1997-01-01'
),
SupplierDetails AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_nationkey,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name, s.s_nationkey
),
CustomerOrderCount AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        COUNT(o.o_orderkey) AS order_count
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
    HAVING 
        COUNT(o.o_orderkey) > 0
),
NationAverage AS (
    SELECT 
        n.n_nationkey,
        AVG(s.s_acctbal) AS avg_acctbal
    FROM 
        nation n
    LEFT JOIN 
        supplier s ON n.n_nationkey = s.s_nationkey
    GROUP BY 
        n.n_nationkey
)
SELECT 
    p.p_name,
    p.p_retailprice,
    COALESCE(sd.total_supply_cost, 0) AS total_supply_cost,
    cac.order_count,
    na.avg_acctbal,
    CASE 
        WHEN o.o_orderstatus = 'O' THEN 'Pending'
        WHEN o.o_orderstatus = 'F' THEN 'Finished'
        ELSE 'Unknown' 
    END AS order_status_description
FROM 
    part p
LEFT JOIN 
    SupplierDetails sd ON p.p_partkey = sd.s_suppkey
LEFT JOIN 
    CustomerOrderCount cac ON cac.c_custkey = sd.s_nationkey
LEFT JOIN 
    NationAverage na ON na.n_nationkey = sd.s_nationkey
LEFT JOIN 
    RankedOrders o ON o.o_orderkey = cac.order_count
WHERE 
    (p.p_retailprice > 50.00 OR sd.total_supply_cost IS NOT NULL) 
    AND na.avg_acctbal IS NOT NULL
ORDER BY 
    p.p_retailprice DESC, total_supply_cost ASC;