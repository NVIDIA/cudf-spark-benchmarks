WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        RANK() OVER (PARTITION BY c.c_mktsegment ORDER BY o.o_totalprice DESC) AS rank_price
    FROM 
        orders o
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
    WHERE 
        o.o_orderstatus = 'O' 
        AND o.o_orderdate >= DATE '1996-01-01' 
        AND o.o_orderdate < DATE '1997-01-01'
), 
SupplierAvailability AS (
    SELECT 
        ps.ps_partkey,
        SUM(ps.ps_availqty) AS total_avail_qty,
        SUM(ps.ps_supplycost) AS total_supply_cost
    FROM 
        partsupp ps
    GROUP BY 
        ps.ps_partkey
), 
PartDetails AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_brand,
        p.p_retailprice,
        RANK() OVER (PARTITION BY p.p_brand ORDER BY p.p_retailprice DESC) AS rank_retail
    FROM 
        part p
    WHERE 
        p.p_size > 10
)

SELECT 
    o.o_orderkey,
    o.o_totalprice,
    o.o_orderdate,
    rd.p_name,
    rd.p_brand,
    sa.total_avail_qty,
    sa.total_supply_cost,
    CASE 
        WHEN sa.total_avail_qty IS NULL THEN 'Unavailable'
        ELSE 'Available'
    END AS availability_status
FROM 
    RankedOrders o
LEFT JOIN 
    lineitem l ON o.o_orderkey = l.l_orderkey
LEFT JOIN 
    PartDetails rd ON l.l_partkey = rd.p_partkey AND rd.rank_retail <= 5
LEFT JOIN 
    SupplierAvailability sa ON l.l_partkey = sa.ps_partkey
WHERE 
    o.rank_price <= 10
ORDER BY 
    o.o_orderdate, o.o_orderkey;