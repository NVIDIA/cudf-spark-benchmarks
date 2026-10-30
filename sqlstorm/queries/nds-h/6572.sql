WITH RankedParts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_brand,
        p.p_retailprice,
        ROW_NUMBER() OVER (PARTITION BY p.p_brand ORDER BY p.p_retailprice DESC) AS rank
    FROM 
        part p
    WHERE 
        p.p_retailprice > 100.00
), SupplierContribution AS (
    SELECT 
        ps.ps_partkey,
        SUM(ps.ps_supplycost) AS total_supply_cost
    FROM 
        partsupp ps
    JOIN 
        RankedParts rp ON ps.ps_partkey = rp.p_partkey
    GROUP BY 
        ps.ps_partkey
), CustomerOrders AS (
    SELECT 
        c.c_custkey,
        SUM(o.o_totalprice) AS total_spent
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    WHERE 
        o.o_orderstatus = 'O'
    GROUP BY 
        c.c_custkey
), OrderLineItems AS (
    SELECT 
        o.o_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS order_value
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        l.l_shipdate >= DATE '1997-01-01' AND l.l_shipdate < DATE '1998-01-01'
    GROUP BY 
        o.o_orderkey
)
SELECT 
    rp.p_name AS part_name,
    rp.p_brand AS part_brand,
    rp.p_retailprice AS retail_price,
    sc.total_supply_cost AS total_supply_cost,
    co.total_spent AS customer_total_spent,
    oli.order_value AS order_total_value
FROM 
    RankedParts rp
JOIN 
    SupplierContribution sc ON rp.p_partkey = sc.ps_partkey
LEFT JOIN 
    CustomerOrders co ON co.c_custkey = (SELECT c_custkey FROM customer ORDER BY c_acctbal DESC LIMIT 1)
LEFT JOIN 
    OrderLineItems oli ON oli.o_orderkey = (SELECT o_orderkey FROM orders ORDER BY o_orderdate DESC LIMIT 1)
WHERE 
    rp.rank <= 5
ORDER BY 
    rp.p_brand, rp.p_retailprice DESC;